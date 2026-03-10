import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID")!;
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID")!;
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY")!;
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") || "fpi-uploads";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
};

// S3v4 signed DELETE request (no AWS SDK needed)
async function hmacSHA256(key: ArrayBuffer, message: string): Promise<ArrayBuffer> {
  const cryptoKey = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return await crypto.subtle.sign("HMAC", cryptoKey, new TextEncoder().encode(message));
}

async function getSigningKey(secretKey: string, date: string, region: string, service: string): Promise<ArrayBuffer> {
  let key = await hmacSHA256(new TextEncoder().encode("AWS4" + secretKey).buffer as ArrayBuffer, date);
  key = await hmacSHA256(key, region);
  key = await hmacSHA256(key, service);
  key = await hmacSHA256(key, "aws4_request");
  return key;
}

function hexEncode(buffer: ArrayBuffer): string {
  return [...new Uint8Array(buffer)].map(b => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(data: string): Promise<string> {
  const hash = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(data));
  return hexEncode(hash);
}

async function deleteFromR2(bucket: string, key: string): Promise<void> {
  const host = `${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const region = "auto";
  const service = "s3";
  const method = "DELETE";
  const path = `/${bucket}/${key}`;

  const now = new Date();
  const dateStamp = now.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
  const date = dateStamp.substring(0, 8);

  const payloadHash = await sha256Hex("");
  const canonicalRequest = [
    method, path, "",
    `host:${host}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${dateStamp}\n`,
    "host;x-amz-content-sha256;x-amz-date",
    payloadHash,
  ].join("\n");

  const stringToSign = [
    "AWS4-HMAC-SHA256", dateStamp,
    `${date}/${region}/${service}/aws4_request`,
    await sha256Hex(canonicalRequest),
  ].join("\n");

  const signingKey = await getSigningKey(R2_SECRET_ACCESS_KEY, date, region, service);
  const signature = hexEncode(await hmacSHA256(signingKey, stringToSign));
  const credential = `${R2_ACCESS_KEY_ID}/${date}/${region}/${service}/aws4_request`;

  await fetch(`https://${host}${path}`, {
    method: "DELETE",
    headers: {
      "Host": host,
      "x-amz-date": dateStamp,
      "x-amz-content-sha256": payloadHash,
      "Authorization": `AWS4-HMAC-SHA256 Credential=${credential}, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=${signature}`,
    },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { file_path } = await req.json();
    if (!file_path) {
      return new Response(JSON.stringify({ error: "Missing file_path" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify file belongs to user
    const { data: usageRow } = await supabase
      .from("storage_usage")
      .select("*")
      .eq("file_path", file_path)
      .eq("user_id", user.id)
      .single();

    if (!usageRow) {
      return new Response(JSON.stringify({ error: "File not found or not owned by user" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    await deleteFromR2(R2_BUCKET_NAME, file_path);

    await supabase.from("storage_usage").delete().eq("file_path", file_path);

    return new Response(JSON.stringify({ success: true }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

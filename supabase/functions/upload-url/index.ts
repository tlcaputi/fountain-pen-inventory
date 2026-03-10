import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GLOBAL_CAP = parseInt(Deno.env.get("GLOBAL_STORAGE_CAP_BYTES") || "10737418240"); // 10 GB
const USER_CAP = parseInt(Deno.env.get("PER_USER_STORAGE_CAP_BYTES") || "104857600"); // 100 MB
const MAX_FILE = parseInt(Deno.env.get("MAX_FILE_SIZE_BYTES") || "3145728"); // 3 MB

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID")!;
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID")!;
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY")!;
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") || "fpi-uploads";
const R2_PUBLIC_URL = Deno.env.get("R2_PUBLIC_URL") || "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
};

// S3v4 presigned URL generation (no AWS SDK needed)
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

async function generatePresignedUrl(bucket: string, key: string, contentType: string, expiresIn = 300): Promise<string> {
  const host = `${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const region = "auto";
  const service = "s3";
  const method = "PUT";

  const now = new Date();
  const dateStamp = now.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
  const date = dateStamp.substring(0, 8);
  const credential = `${R2_ACCESS_KEY_ID}/${date}/${region}/${service}/aws4_request`;

  const queryParams = new URLSearchParams({
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": credential,
    "X-Amz-Date": dateStamp,
    "X-Amz-Expires": String(expiresIn),
    "X-Amz-SignedHeaders": "content-type;host",
  });

  const canonicalRequest = [
    method,
    `/${bucket}/${key}`,
    queryParams.toString(),
    `content-type:${contentType}\nhost:${host}\n`,
    "content-type;host",
    "UNSIGNED-PAYLOAD",
  ].join("\n");

  const stringToSign = [
    "AWS4-HMAC-SHA256",
    dateStamp,
    `${date}/${region}/${service}/aws4_request`,
    await sha256Hex(canonicalRequest),
  ].join("\n");

  const signingKey = await getSigningKey(R2_SECRET_ACCESS_KEY, date, region, service);
  const signature = hexEncode(await hmacSHA256(signingKey, stringToSign));

  queryParams.set("X-Amz-Signature", signature);
  return `https://${host}/${bucket}/${key}?${queryParams.toString()}`;
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

    const { filename, file_size_bytes, content_type } = await req.json();
    if (!filename || !file_size_bytes || !content_type) {
      return new Response(JSON.stringify({ error: "Missing filename, file_size_bytes, or content_type" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const allowedTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];
    if (!allowedTypes.includes(content_type)) {
      return new Response(JSON.stringify({ error: "Invalid file type. Allowed: JPEG, PNG, WebP, GIF" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (file_size_bytes > MAX_FILE) {
      return new Response(JSON.stringify({ error: `File too large. Maximum ${MAX_FILE / 1048576} MB` }), {
        status: 413, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Global cap
    const { data: allRows } = await supabase.from("storage_usage").select("file_size_bytes");
    const globalUsage = allRows?.reduce((sum: number, r: { file_size_bytes: number }) => sum + r.file_size_bytes, 0) || 0;
    if (globalUsage + file_size_bytes > GLOBAL_CAP) {
      return new Response(JSON.stringify({ error: "Global storage limit reached (10 GB)" }), {
        status: 507, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Per-user cap
    const { data: userRows } = await supabase.from("storage_usage").select("file_size_bytes").eq("user_id", user.id);
    const userUsage = userRows?.reduce((sum: number, r: { file_size_bytes: number }) => sum + r.file_size_bytes, 0) || 0;
    if (userUsage + file_size_bytes > USER_CAP) {
      return new Response(JSON.stringify({ error: `User storage limit reached (${USER_CAP / 1048576} MB)` }), {
        status: 507, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const filePath = `${user.id}/${filename}`;

    // Reserve space
    const { error: insertError } = await supabase
      .from("storage_usage")
      .upsert({
        user_id: user.id,
        file_path: filePath,
        file_size_bytes,
        content_type,
        uploaded_at: new Date().toISOString(),
      }, { onConflict: "file_path" });

    if (insertError) {
      return new Response(JSON.stringify({ error: "Failed to reserve storage: " + insertError.message }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const presignedUrl = await generatePresignedUrl(R2_BUCKET_NAME, filePath, content_type);
    const publicUrl = `${R2_PUBLIC_URL}/${filePath}`;

    return new Response(JSON.stringify({ presigned_url: presignedUrl, public_url: publicUrl, file_path: filePath }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

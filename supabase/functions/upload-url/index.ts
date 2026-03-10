import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { S3Client, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3";
import { getSignedUrl } from "https://esm.sh/@aws-sdk/s3-request-presigner@3";

const GLOBAL_CAP = parseInt(Deno.env.get("GLOBAL_STORAGE_CAP_BYTES") || "10737418240"); // 10 GB
const USER_CAP = parseInt(Deno.env.get("PER_USER_STORAGE_CAP_BYTES") || "104857600"); // 100 MB
const MAX_FILE = parseInt(Deno.env.get("MAX_FILE_SIZE_BYTES") || "3145728"); // 3 MB

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID")!;
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID")!;
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY")!;
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") || "fpi-uploads";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Verify JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
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
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Parse request
    const { filename, file_size_bytes, content_type } = await req.json();
    if (!filename || !file_size_bytes || !content_type) {
      return new Response(JSON.stringify({ error: "Missing filename, file_size_bytes, or content_type" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Validate content type
    const allowedTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];
    if (!allowedTypes.includes(content_type)) {
      return new Response(JSON.stringify({ error: "Invalid file type. Allowed: JPEG, PNG, WebP, GIF" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Per-file cap
    if (file_size_bytes > MAX_FILE) {
      return new Response(JSON.stringify({ error: `File too large. Maximum ${MAX_FILE / 1048576} MB` }), {
        status: 413,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Global cap check
    const { data: globalUsage } = await supabase
      .from("storage_usage")
      .select("file_size_bytes")
      .then(({ data }) => ({
        data: data?.reduce((sum: number, r: { file_size_bytes: number }) => sum + r.file_size_bytes, 0) || 0,
      }));

    if ((globalUsage as number) + file_size_bytes > GLOBAL_CAP) {
      return new Response(JSON.stringify({ error: "Global storage limit reached (10 GB)" }), {
        status: 507,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Per-user cap check
    const { data: userRows } = await supabase
      .from("storage_usage")
      .select("file_size_bytes")
      .eq("user_id", user.id);

    const userUsage = userRows?.reduce((sum: number, r: { file_size_bytes: number }) => sum + r.file_size_bytes, 0) || 0;
    if (userUsage + file_size_bytes > USER_CAP) {
      return new Response(JSON.stringify({ error: `User storage limit reached (${USER_CAP / 1048576} MB)` }), {
        status: 507,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Build R2 file path
    const filePath = `${user.id}/${filename}`;

    // Reserve space in storage_usage
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
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate presigned URL
    const s3Client = new S3Client({
      region: "auto",
      endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID,
        secretAccessKey: R2_SECRET_ACCESS_KEY,
      },
    });

    const command = new PutObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: filePath,
      ContentType: content_type,
      ContentLength: file_size_bytes,
    });

    const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 }); // 5 minutes

    const R2_PUBLIC_URL = Deno.env.get("R2_PUBLIC_URL") || "";
    const publicUrl = `${R2_PUBLIC_URL}/${filePath}`;

    return new Response(JSON.stringify({
      presigned_url: presignedUrl,
      public_url: publicUrl,
      file_path: filePath,
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

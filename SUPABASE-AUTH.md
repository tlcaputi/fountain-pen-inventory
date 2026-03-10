# Fountain Pen Inventory — Supabase & Auth Setup

## What I Need From You

Before I can configure the backend, I need the following:

### 1. Supabase Project (Done)

| Item | Value |
|------|-------|
| **Project URL** | `https://dbrfpmrngreaqoggamfx.supabase.co` |
| **Publishable Key** | `sb_publishable_qsPZ-YBrbZnkFLV6luWbew_o-0D6aNx` |

### 2. GitHub Pages URL

What URL will the site be deployed at? This is needed for auth redirect configuration.

Options:
- `https://tlcaputi.github.io/fountain-pen-inventory` (default GitHub Pages)
- `https://fpi.bankbonimus.com` (custom domain)
- Something else?

### 3. Email Configuration (for auth emails)

Supabase's built-in email service has a **2 emails/hour rate limit** — fine for development, not for production. For production, you'll need an SMTP provider. Options:

| Provider | Free Tier | Setup |
|----------|-----------|-------|
| **Resend** | 3,000 emails/month | Easiest; just need API key |
| **SendGrid** | 100 emails/day | Common; needs domain verification |
| **Postmark** | 100 emails/month | Good deliverability |
| **Skip for now** | 2/hour limit | Fine for dev/testing |

**Decision needed:** Which provider, or skip for now?

### 4. OAuth Providers (Optional, can add later)

If you want Google or GitHub login in addition to email/password:

**Google OAuth:**
- Requires a Google Cloud project with OAuth Client credentials
- You'd configure it at https://console.cloud.google.com/auth/clients

**GitHub OAuth:**
- Requires an OAuth App at https://github.com/settings/developers

**Decision needed:** Include OAuth in v1, or email-only for now?

### 5. Custom Domain DNS (if using one)

If using `fpi.bankbonimus.com`:
- You'll need to add a CNAME record pointing to `tlcaputi.github.io`
- GitHub Pages needs the custom domain configured in repo settings

---

## What I'll Configure (No Action Needed From You)

Everything below will be done via SQL migrations and code. You don't need to do anything in the Supabase dashboard for these.

---

## Auth Flow (Email/Password, Static Site)

### How It Works

1. **Signup:** User fills out email + password → `supabase.auth.signUp()` → Supabase sends confirmation email → user clicks link → redirected back to app with session tokens in URL hash
2. **Login:** User enters email + password → `supabase.auth.signInWithPassword()` → session tokens stored in `localStorage`
3. **Password Reset:** User clicks "Forgot password" → `supabase.auth.resetPasswordForEmail()` → email with reset link → user clicks link → redirected to app → `supabase.auth.updateUser({ password })`
4. **Session Persistence:** Supabase JS client auto-refreshes tokens from `localStorage`; `onAuthStateChange` listener syncs auth state across browser tabs
5. **Logout:** `supabase.auth.signOut()` → clears session → redirect to login

### Auth Redirect Configuration (Supabase Dashboard)

These need to be set in **Authentication > URL Configuration**:

| Setting | Development | Production |
|---------|------------|------------|
| Site URL | `http://localhost:5173` | `https://pens.bankbonimus.com` |
| Redirect URLs | `http://localhost:5173/**` | `https://pens.bankbonimus.com/**` |

### Email Confirmation

- **Development:** disable in Authentication > Providers > Email (uncheck "Confirm email") for easier testing
- **Production:** keep enabled; customize email templates in Authentication > Email Templates

---

## Database Schema (SQL Migration)

All tables below will be created via a single SQL migration file.

### profiles

```sql
CREATE TABLE public.profiles (
  id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  address1 TEXT,
  address2 TEXT,
  city TEXT,
  state TEXT,
  province TEXT,
  zip TEXT,
  country TEXT,
  phone TEXT,
  email TEXT,
  fpn_username TEXT,
  photo_folder_url TEXT,
  preferred_currency TEXT DEFAULT 'USD',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### pens

```sql
CREATE TABLE public.pens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,

  -- Identity
  model TEXT,
  manufacturer TEXT,
  manufacturer_and_model TEXT GENERATED ALWAYS AS (
    COALESCE(manufacturer, '') || ' ' || COALESCE(model, '')
  ) STORED,
  description TEXT,
  pen_type TEXT,
  year_made TEXT,

  -- Physical
  color TEXT,
  primary_material TEXT,
  body_material TEXT,
  size TEXT,
  length TEXT,
  length_posted TEXT,
  diameter TEXT,
  weight TEXT,
  cap_type TEXT,

  -- Nib
  nib_stroke TEXT,
  nib_material TEXT,
  nib_flex TEXT,
  nib_modification TEXT,

  -- Filling
  filler TEXT,

  -- Condition
  condition_rating NUMERIC,
  new_used TEXT,
  repair_required TEXT,
  repair_cost NUMERIC,
  repaired_by TEXT,

  -- Reviews
  first_impression TEXT,
  appearance TEXT,
  design TEXT,
  nib_review TEXT,
  filling_system_review TEXT,
  cost_and_value TEXT,
  conclusion TEXT,
  comments TEXT,
  miscellaneous TEXT,

  -- Ratings (1-10)
  first_impression_rating NUMERIC,
  appearance_rating NUMERIC,
  design_rating NUMERIC,
  nib_rating NUMERIC,
  filling_system_rating NUMERIC,
  cost_and_value_rating NUMERIC,
  total_rating NUMERIC GENERATED ALWAYS AS (
    CASE WHEN (
      COALESCE(first_impression_rating, 0) + COALESCE(appearance_rating, 0) +
      COALESCE(design_rating, 0) + COALESCE(nib_rating, 0) +
      COALESCE(filling_system_rating, 0) + COALESCE(cost_and_value_rating, 0)
    ) > 0
    THEN ROUND((
      COALESCE(first_impression_rating, 0) + COALESCE(appearance_rating, 0) +
      COALESCE(design_rating, 0) + COALESCE(nib_rating, 0) +
      COALESCE(filling_system_rating, 0) + COALESCE(cost_and_value_rating, 0)
    ) / NULLIF(
      (CASE WHEN first_impression_rating IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN appearance_rating IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN design_rating IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN nib_rating IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN filling_system_rating IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN cost_and_value_rating IS NOT NULL THEN 1 ELSE 0 END)
    , 0), 1)
    ELSE NULL END
  ) STORED,

  -- Purchase
  purchase_price NUMERIC,
  purchase_price_currency TEXT DEFAULT 'USD',
  purchase_date DATE,
  purchased_from TEXT,
  shipping_cost NUMERIC,
  retail_price NUMERIC,
  localized_purchase_price NUMERIC,

  -- Sale
  selling_price NUMERIC,
  selling_date DATE,
  sold_to TEXT,
  traded_for TEXT,
  qty_sold INTEGER,

  -- Valuation
  current_value NUMERIC,
  valuation_date DATE,

  -- Photos (URLs to Cloudflare R2)
  photo_closed_url TEXT,
  photo_open_url TEXT,
  photo_posted_url TEXT,
  photo_nib_url TEXT,
  photo_converter_url TEXT,
  photo_closed_caption TEXT,

  -- Metadata
  quantity INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pens_user_id ON public.pens USING btree (user_id);
```

### pen_photos

```sql
CREATE TABLE public.pen_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  pen_id UUID REFERENCES public.pens ON DELETE CASCADE,
  ink_id UUID REFERENCES public.inks ON DELETE SET NULL,
  photo_url TEXT NOT NULL,
  caption TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pen_photos_user_id ON public.pen_photos USING btree (user_id);
CREATE INDEX idx_pen_photos_pen_id ON public.pen_photos USING btree (pen_id);
```

### inks

```sql
CREATE TABLE public.inks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,

  -- Identity
  ink_name TEXT,
  manufacturer TEXT,
  fpn_color_category TEXT,

  -- Properties
  color_description TEXT,
  special_features TEXT,
  drying_speed TEXT,
  opacity TEXT,
  waterproof_rating TEXT,
  feathering TEXT,
  ph TEXT,
  sunlight_resistance TEXT,
  saturation TEXT,
  shading TEXT,
  sample_bottle_mix TEXT,
  do_not_mix BOOLEAN DEFAULT FALSE,

  -- Ratings
  color_rating NUMERIC,
  overall_rating NUMERIC,

  -- Purchase
  purchase_date DATE,
  purchase_price NUMERIC,
  purchase_price_currency TEXT DEFAULT 'USD',
  purchased_from TEXT,
  retail_price NUMERIC,
  shipping_cost NUMERIC,
  localized_purchase_price NUMERIC,

  -- Bottle
  bottle_volume TEXT,
  bottle_notes TEXT,

  -- Media
  main_photo_url TEXT,
  caption TEXT,
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inks_user_id ON public.inks USING btree (user_id);
```

### ink_recipes

```sql
CREATE TABLE public.ink_recipes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  name TEXT,
  color_description TEXT,
  recipe TEXT,
  notes TEXT,
  fpn_color_category TEXT,
  date_created DATE DEFAULT CURRENT_DATE,
  date_modified DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ink_recipes_user_id ON public.ink_recipes USING btree (user_id);
```

### manufacturers

```sql
CREATE TABLE public.manufacturers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  manufacturer TEXT NOT NULL,
  country TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_manufacturers_user_id ON public.manufacturers USING btree (user_id);
```

### finishes

```sql
CREATE TABLE public.finishes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  finish TEXT NOT NULL,
  abbreviation TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_finishes_user_id ON public.finishes USING btree (user_id);
```

### currencies (global)

```sql
CREATE TABLE public.currencies (
  id SERIAL PRIMARY KEY,
  currency_symbol TEXT,
  country TEXT,
  currency TEXT,
  value_in_dollars NUMERIC,
  subdivision TEXT,
  iso4217_code TEXT,
  currency_code TEXT,
  country_currency TEXT,
  regime TEXT,
  num TEXT,
  digits INTEGER DEFAULT 2
);
```

### links

```sql
CREATE TABLE public.links (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  url TEXT,
  name TEXT,
  description TEXT,
  type TEXT,
  valid BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_links_user_id ON public.links USING btree (user_id);
```

### changelog (global)

```sql
CREATE TABLE public.changelog (
  id SERIAL PRIMARY KEY,
  date_created DATE,
  time_created TIME,
  change TEXT,
  version TEXT
);
```

---

## Row-Level Security (RLS)

### Template for All User-Scoped Tables

Applied to: `profiles`, `pens`, `pen_photos`, `inks`, `ink_recipes`, `manufacturers`, `finishes`, `links`

```sql
ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY;

-- For profiles, the FK column is `id`, not `user_id`
-- For all other tables, the FK column is `user_id`

CREATE POLICY "Users can view own data"
ON public.<table> FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own data"
ON public.<table> FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own data"
ON public.<table> FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own data"
ON public.<table> FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);
```

### Global Tables (Read-Only)

```sql
ALTER TABLE public.currencies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read currencies"
ON public.currencies FOR SELECT TO authenticated USING (true);

ALTER TABLE public.changelog ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read changelog"
ON public.changelog FOR SELECT TO authenticated USING (true);
```

### Performance Note

Using `(SELECT auth.uid())` (wrapped in a subquery) instead of bare `auth.uid()` forces PostgreSQL to cache the value — benchmarks show up to 95% faster policy evaluation. All policies above use this pattern.

---

## Photo Storage — Cloudflare R2

We use Cloudflare R2 instead of Supabase Storage for photos. R2 gives 10 GB free with zero egress fees vs Supabase's 1 GB (shared across all users).

### R2 Configuration (Already Done)

| Item | Value |
|------|-------|
| Account ID | `bab65d566ec91f24744655e2543428ab` |
| S3 Endpoint | `https://bab65d566ec91f24744655e2543428ab.r2.cloudflarestorage.com` |
| Bucket | `fpi-uploads` (to be created in dashboard) |
| Public URL | `https://pub-e0a99e8fcc0747c9968d29317d1cad48.r2.dev` |
| Access Key ID | Stored as Supabase Edge Function secret |
| Secret Access Key | Stored as Supabase Edge Function secret |

### CORS Configuration (Apply in R2 Bucket Settings)

```json
[
  {
    "AllowedOrigins": [
      "https://pens.bankbonimus.com",
      "http://localhost:5173"
    ],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedHeaders": ["content-type"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

### Storage Tracking Table (Supabase)

Every upload is tracked in Supabase so we can enforce the 10 GB global cap.

```sql
CREATE TABLE public.storage_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  file_path TEXT NOT NULL UNIQUE,        -- R2 object key (e.g., "{user_id}/pen_123_closed.jpg")
  file_size_bytes BIGINT NOT NULL,       -- exact size of the uploaded file
  content_type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_storage_usage_user_id ON public.storage_usage USING btree (user_id);

-- Materialized view for fast global total (refreshed by Edge Function)
-- Not using a materialized view because they can't be refreshed from Edge Functions.
-- Instead, we query SUM() directly — it's fast with the index.
```

RLS policies for `storage_usage`:

```sql
ALTER TABLE public.storage_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own storage usage"
ON public.storage_usage FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- INSERT/UPDATE/DELETE only via Edge Function (service role), not client
-- No insert/update/delete policies = users cannot manipulate their own usage records
```

### Upload Flow (Bulletproof 10 GB Cap)

```
Browser                          Supabase Edge Function                    Cloudflare R2
  │                                       │                                      │
  │ 1. Compress image client-side         │                                      │
  │    (max 1200px, quality 80,           │                                      │
  │     target ~300KB)                    │                                      │
  │                                       │                                      │
  │ 2. POST /functions/v1/upload-url      │                                      │
  │    { filename, file_size_bytes,       │                                      │
  │      content_type }                   │                                      │
  │    Authorization: Bearer <jwt>        │                                      │
  │──────────────────────────────────────>│                                      │
  │                                       │                                      │
  │                                       │ 3. Verify JWT → extract user_id      │
  │                                       │                                      │
  │                                       │ 4. HARD CAP CHECK:                   │
  │                                       │    SELECT SUM(file_size_bytes)        │
  │                                       │    FROM storage_usage;               │
  │                                       │    → If (total + new_file) > 10 GB   │
  │                                       │      → REJECT with 507 error         │
  │                                       │                                      │
  │                                       │ 5. PER-USER CAP CHECK:               │
  │                                       │    SELECT SUM(file_size_bytes)        │
  │                                       │    FROM storage_usage                 │
  │                                       │    WHERE user_id = $1;               │
  │                                       │    → If (user_total + new) > 100 MB  │
  │                                       │      → REJECT with 507 error         │
  │                                       │                                      │
  │                                       │ 6. FILE SIZE CHECK:                  │
  │                                       │    → If file_size > 3 MB             │
  │                                       │      → REJECT (too large)            │
  │                                       │                                      │
  │                                       │ 7. INSERT into storage_usage          │
  │                                       │    (user_id, file_path,              │
  │                                       │     file_size_bytes, content_type)   │
  │                                       │    → This RESERVES the space         │
  │                                       │                                      │
  │                                       │ 8. Generate presigned PUT URL         │
  │                                       │    for path: {user_id}/{filename}    │
  │                                       │    with Content-Length condition      │
  │                                       │    TTL: 5 minutes                    │
  │                     9. Return URL     │                                      │
  │<──────────────────────────────────────│                                      │
  │                                       │                                      │
  │ 10. PUT <presigned_url>               │                                      │
  │     Body: <compressed image bytes>    │                                      │
  │     Content-Type: image/jpeg          │                                      │
  │─────────────────────────────────────────────────────────────────────────────>│
  │                                       │                                      │
  │                                       │                          11. 200 OK  │
  │<─────────────────────────────────────────────────────────────────────────────│
  │                                       │                                      │
  │ 12. Save R2 URL to Supabase DB        │                                      │
  │     (pens.photo_closed_url, etc.)     │                                      │
```

### Why This Is Bulletproof

1. **Space is reserved BEFORE the presigned URL is generated** (step 7). Even if the upload fails, the space is reserved. A cleanup job can release orphaned reservations after 10 minutes.
2. **The presigned URL has a Content-Length condition** — the browser cannot upload a file larger than what was declared.
3. **The presigned URL expires in 5 minutes** — no long-lived upload URLs floating around.
4. **Three layers of enforcement:**
   - Global cap: 10 GB across all users (hard stop)
   - Per-user cap: 100 MB per user (prevents one user from consuming all storage)
   - Per-file cap: 3 MB per file (after client-side compression)
5. **Users cannot manipulate `storage_usage`** — no INSERT/UPDATE/DELETE RLS policies on the table. Only the Edge Function (using service role key) can write to it.
6. **Deletion flow:** when a user deletes a photo, the Edge Function deletes from R2 AND removes the `storage_usage` row, freeing the space.

### Delete Flow

```
Browser                          Supabase Edge Function                    Cloudflare R2
  │                                       │                                      │
  │ 1. POST /functions/v1/delete-photo    │                                      │
  │    { file_path }                      │                                      │
  │    Authorization: Bearer <jwt>        │                                      │
  │──────────────────────────────────────>│                                      │
  │                                       │ 2. Verify JWT → extract user_id      │
  │                                       │ 3. Verify file_path belongs to user  │
  │                                       │    (check storage_usage table)        │
  │                                       │                                      │
  │                                       │ 4. DELETE object from R2              │
  │                                       │────────────────────────────────────>  │
  │                                       │                                      │
  │                                       │ 5. DELETE from storage_usage          │
  │                                       │ 6. DELETE/UPDATE photo URL in         │
  │                                       │    pens/pen_photos/inks table         │
  │                     7. 200 OK         │                                      │
  │<──────────────────────────────────────│                                      │
```

### Orphan Cleanup (Cron or Manual)

If a presigned URL is generated (space reserved in `storage_usage`) but the upload never completes:

```sql
-- Run periodically to reclaim orphaned reservations
-- An orphan = storage_usage row exists but the R2 object doesn't
-- The Edge Function can check R2 HeadObject and delete orphans older than 10 minutes
DELETE FROM public.storage_usage
WHERE uploaded_at < NOW() - INTERVAL '10 minutes'
AND file_path NOT IN (SELECT photo_url FROM ... ); -- cross-check with actual photo references
```

### Edge Function Secrets (Stored in Supabase)

These are set via `supabase secrets set` and never appear in frontend code:

```
R2_ACCOUNT_ID=bab65d566ec91f24744655e2543428ab
R2_ACCESS_KEY_ID=<stored securely>
R2_SECRET_ACCESS_KEY=<stored securely>
R2_BUCKET_NAME=fpi-uploads
R2_PUBLIC_URL=https://pub-e0a99e8fcc0747c9968d29317d1cad48.r2.dev
GLOBAL_STORAGE_CAP_BYTES=10737418240   # 10 GB exactly
PER_USER_STORAGE_CAP_BYTES=104857600   # 100 MB
MAX_FILE_SIZE_BYTES=3145728            # 3 MB
```

---

## Auto-Create Profile on Signup

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, first_name, last_name, email)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'first_name',
    NEW.raw_user_meta_data ->> 'last_name',
    NEW.email
  );

  -- Seed default manufacturers (subset — full list in seed migration)
  INSERT INTO public.manufacturers (user_id, manufacturer, country)
  VALUES
    (NEW.id, 'Aurora', 'Italy'),
    (NEW.id, 'Conway Stewart', 'United Kingdom'),
    (NEW.id, 'Cross', 'United States'),
    (NEW.id, 'Delta', 'Italy'),
    (NEW.id, 'Faber-Castell', 'Germany'),
    (NEW.id, 'Lamy', 'Germany'),
    (NEW.id, 'Montblanc', 'Germany'),
    (NEW.id, 'Montegrappa', 'Italy'),
    (NEW.id, 'Nakaya', 'Japan'),
    (NEW.id, 'Namiki', 'Japan'),
    (NEW.id, 'Omas', 'Italy'),
    (NEW.id, 'Parker', 'United States'),
    (NEW.id, 'Pelikan', 'Germany'),
    (NEW.id, 'Pilot', 'Japan'),
    (NEW.id, 'Platinum', 'Japan'),
    (NEW.id, 'Sailor', 'Japan'),
    (NEW.id, 'Sheaffer', 'United States'),
    (NEW.id, 'Stipula', 'Italy'),
    (NEW.id, 'Visconti', 'Italy'),
    (NEW.id, 'Waterman', 'France');

  -- Seed default finishes
  INSERT INTO public.finishes (user_id, finish, abbreviation)
  VALUES
    (NEW.id, 'High Polish', 'HP'),
    (NEW.id, 'Matte', 'MT'),
    (NEW.id, 'Brushed', 'BR'),
    (NEW.id, 'Lacquer', 'LQ'),
    (NEW.id, 'Celluloid', 'CL'),
    (NEW.id, 'Resin', 'RS'),
    (NEW.id, 'Ebonite', 'EB'),
    (NEW.id, 'Urushi', 'UR'),
    (NEW.id, 'Metal', 'MT'),
    (NEW.id, 'Sterling Silver', 'SS');

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

---

## JS Client Setup (Frontend)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://<project-ref>.supabase.co',  // from env/config
  'sb_publishable_...'                   // from env/config
)

// Auth state listener (runs on every page load)
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT' || !session) {
    // redirect to login
  }
  // SIGNED_IN, TOKEN_REFRESHED, etc. — update app state
})
```

### GitHub Pages SPA Routing Fix

GitHub Pages returns 404 for client-side routes (e.g., `/pens/123`). The fix:

1. Create a `404.html` that encodes the path as a query param and redirects to `index.html`
2. In `index.html`, restore the original path via `history.replaceState`

This is handled automatically by SvelteKit's `adapter-static` with `fallback: '404.html'`.

---

## Checklist: What Happens Where

| Task | Where |
|------|-------|
| Create Supabase project | Dashboard (you) |
| Get API keys | Dashboard (you) |
| Set Site URL + Redirect URLs | Dashboard (you) |
| Enable/disable email confirmation | Dashboard (you) |
| Configure SMTP (production) | Dashboard (you) |
| Create R2 bucket `fpi-uploads` | Cloudflare Dashboard (you) |
| Enable R2.dev public access | Cloudflare Dashboard (you) |
| Set R2 CORS policy | Cloudflare Dashboard (you) |
| Create database tables | SQL migration (me) |
| Enable RLS + policies | SQL migration (me) |
| Create trigger function | SQL migration (me) |
| Create `storage_usage` tracking table | SQL migration (me) |
| Create upload/delete Edge Functions | Code (me) |
| Set Edge Function secrets (R2 keys) | Supabase CLI (me) |
| Seed currencies data | SQL migration (me) |
| Seed changelog data | SQL migration (me) |
| Frontend auth UI | Code (me) |
| All frontend code | Code (me) |

-- ============================================
-- Fountain Pen Inventory — Full Schema Migration
-- ============================================

-- 1. PROFILES
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

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);


-- 2. PENS
CREATE TABLE public.pens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,

  -- Identity
  model TEXT,
  manufacturer TEXT,
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
  photo_open_caption TEXT,
  photo_posted_caption TEXT,
  photo_nib_caption TEXT,
  photo_converter_caption TEXT,

  -- Metadata
  quantity INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pens_user_id ON public.pens USING btree (user_id);

ALTER TABLE public.pens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own pens"
ON public.pens FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own pens"
ON public.pens FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own pens"
ON public.pens FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own pens"
ON public.pens FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 3. INKS (must be created before pen_photos due to FK)
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

ALTER TABLE public.inks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own inks"
ON public.inks FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own inks"
ON public.inks FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own inks"
ON public.inks FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own inks"
ON public.inks FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 4. PEN PHOTOS
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

ALTER TABLE public.pen_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own pen photos"
ON public.pen_photos FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own pen photos"
ON public.pen_photos FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own pen photos"
ON public.pen_photos FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own pen photos"
ON public.pen_photos FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 5. INK RECIPES
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

ALTER TABLE public.ink_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ink recipes"
ON public.ink_recipes FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own ink recipes"
ON public.ink_recipes FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own ink recipes"
ON public.ink_recipes FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own ink recipes"
ON public.ink_recipes FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 6. MANUFACTURERS
CREATE TABLE public.manufacturers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  manufacturer TEXT NOT NULL,
  country TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_manufacturers_user_id ON public.manufacturers USING btree (user_id);

ALTER TABLE public.manufacturers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own manufacturers"
ON public.manufacturers FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own manufacturers"
ON public.manufacturers FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own manufacturers"
ON public.manufacturers FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own manufacturers"
ON public.manufacturers FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 7. FINISHES
CREATE TABLE public.finishes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  finish TEXT NOT NULL,
  abbreviation TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_finishes_user_id ON public.finishes USING btree (user_id);

ALTER TABLE public.finishes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own finishes"
ON public.finishes FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own finishes"
ON public.finishes FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own finishes"
ON public.finishes FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own finishes"
ON public.finishes FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 8. CURRENCIES (global, read-only for users)
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

ALTER TABLE public.currencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read currencies"
ON public.currencies FOR SELECT TO authenticated
USING (true);


-- 9. LINKS
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

ALTER TABLE public.links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own links"
ON public.links FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own links"
ON public.links FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own links"
ON public.links FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own links"
ON public.links FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 10. CHANGELOG (global, read-only)
CREATE TABLE public.changelog (
  id SERIAL PRIMARY KEY,
  date_created DATE,
  time_created TIME,
  change TEXT,
  version TEXT
);

ALTER TABLE public.changelog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read changelog"
ON public.changelog FOR SELECT TO authenticated
USING (true);


-- 11. STORAGE USAGE (for R2 10GB cap enforcement)
CREATE TABLE public.storage_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  file_path TEXT NOT NULL UNIQUE,
  file_size_bytes BIGINT NOT NULL,
  content_type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_storage_usage_user_id ON public.storage_usage USING btree (user_id);

ALTER TABLE public.storage_usage ENABLE ROW LEVEL SECURITY;

-- Users can only view their own storage usage (no insert/update/delete via client)
CREATE POLICY "Users can view own storage usage"
ON public.storage_usage FOR SELECT TO authenticated
USING ((SELECT auth.uid()) = user_id);


-- 12. AUTO-CREATE PROFILE ON SIGNUP
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

  -- Seed default manufacturers
  INSERT INTO public.manufacturers (user_id, manufacturer, country)
  VALUES
    (NEW.id, 'Aurora', 'Italy'),
    (NEW.id, 'Benu', 'Austria'),
    (NEW.id, 'Conklin', 'United States'),
    (NEW.id, 'Conway Stewart', 'United Kingdom'),
    (NEW.id, 'Cross', 'United States'),
    (NEW.id, 'Delta', 'Italy'),
    (NEW.id, 'Diplomat', 'Germany'),
    (NEW.id, 'Edison', 'United States'),
    (NEW.id, 'Esterbrook', 'United States'),
    (NEW.id, 'Faber-Castell', 'Germany'),
    (NEW.id, 'Franklin-Christoph', 'United States'),
    (NEW.id, 'Kaweco', 'Germany'),
    (NEW.id, 'Lamy', 'Germany'),
    (NEW.id, 'Leonardo', 'Italy'),
    (NEW.id, 'Montblanc', 'Germany'),
    (NEW.id, 'Montegrappa', 'Italy'),
    (NEW.id, 'Nakaya', 'Japan'),
    (NEW.id, 'Namiki', 'Japan'),
    (NEW.id, 'Narwhal', 'Pakistan'),
    (NEW.id, 'Noodler''s', 'United States'),
    (NEW.id, 'Omas', 'Italy'),
    (NEW.id, 'Opus 88', 'Taiwan'),
    (NEW.id, 'Parker', 'United States'),
    (NEW.id, 'Pelikan', 'Germany'),
    (NEW.id, 'Penbbs', 'China'),
    (NEW.id, 'Pilot', 'Japan'),
    (NEW.id, 'Platinum', 'Japan'),
    (NEW.id, 'Sailor', 'Japan'),
    (NEW.id, 'Scribo', 'Italy'),
    (NEW.id, 'Sheaffer', 'United States'),
    (NEW.id, 'Stipula', 'Italy'),
    (NEW.id, 'Taccia', 'Japan'),
    (NEW.id, 'TWSBI', 'Taiwan'),
    (NEW.id, 'Visconti', 'Italy'),
    (NEW.id, 'Wahl-Eversharp', 'United States'),
    (NEW.id, 'Waterman', 'France');

  -- Seed default finishes
  INSERT INTO public.finishes (user_id, finish, abbreviation)
  VALUES
    (NEW.id, 'High Polish', 'HP'),
    (NEW.id, 'Matte', 'MA'),
    (NEW.id, 'Brushed', 'BR'),
    (NEW.id, 'Satin', 'SA'),
    (NEW.id, 'Lacquer', 'LQ'),
    (NEW.id, 'Celluloid', 'CL'),
    (NEW.id, 'Resin', 'RS'),
    (NEW.id, 'Ebonite', 'EB'),
    (NEW.id, 'Urushi', 'UR'),
    (NEW.id, 'Metal', 'ME'),
    (NEW.id, 'Sterling Silver', 'SS'),
    (NEW.id, 'Gold Filled', 'GF'),
    (NEW.id, 'Demonstrator', 'DM');

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- 13. PUBLIC SHARING
ALTER TABLE public.pens ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS collection_public BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS share_slug TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_share_slug ON public.profiles (share_slug) WHERE share_slug IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pens_is_public ON public.pens (is_public) WHERE is_public = true;

-- Anon read policies for public sharing
CREATE POLICY "Anon can view public pens"
ON public.pens FOR SELECT TO anon
USING (
  is_public = true
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = pens.user_id AND collection_public = true)
);

CREATE POLICY "Anon can view photos of public pens"
ON public.pen_photos FOR SELECT TO anon
USING (
  EXISTS (
    SELECT 1 FROM public.pens
    WHERE pens.id = pen_photos.pen_id
    AND (pens.is_public = true
         OR EXISTS (SELECT 1 FROM public.profiles WHERE id = pens.user_id AND collection_public = true))
  )
);

CREATE POLICY "Anon can view public profiles"
ON public.profiles FOR SELECT TO anon
USING (collection_public = true);


-- 14. INITIAL CHANGELOG ENTRIES
INSERT INTO public.changelog (date_created, version, change) VALUES
  ('2026-03-10', '2.0.0', 'Web rebuild of Fountain Pen Inventory — launched as pens.bankbonimus.com');

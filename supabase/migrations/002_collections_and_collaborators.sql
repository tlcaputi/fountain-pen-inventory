-- Migration 002: Collections, Collaborators, and Public Sharing
-- Applied manually via Supabase Management API on 2026-03-11

-- =============================================================================
-- COLLECTIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN NOT NULL DEFAULT false,
  share_slug TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- Owner can do everything with their own collections
CREATE POLICY collections_owner_all ON collections
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Anon can read public collections
CREATE POLICY anon_read_public_collections ON collections
  FOR SELECT TO anon
  USING (is_public = true);

-- =============================================================================
-- COLLECTION_PENS (junction table)
-- =============================================================================

CREATE TABLE IF NOT EXISTS collection_pens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  pen_id UUID NOT NULL REFERENCES pens(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(collection_id, pen_id)
);

ALTER TABLE collection_pens ENABLE ROW LEVEL SECURITY;

-- Owner of the collection can manage pens in it
CREATE POLICY collection_pens_owner ON collection_pens
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM collections c WHERE c.id = collection_id AND c.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM collections c WHERE c.id = collection_id AND c.user_id = auth.uid()
  ));

-- Collaborators with collection-level edit can manage pens
CREATE POLICY collection_pens_collaborator ON collection_pens
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM collaborators col
    WHERE col.collaborator_id = auth.uid()
      AND col.scope = 'collection'
      AND col.collection_id = collection_pens.collection_id
      AND col.permission = 'edit'
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM collaborators col
    WHERE col.collaborator_id = auth.uid()
      AND col.scope = 'collection'
      AND col.collection_id = collection_pens.collection_id
      AND col.permission = 'edit'
  ));

-- Anon can read pens in public collections
CREATE POLICY anon_read_collection_pens ON collection_pens
  FOR SELECT TO anon
  USING (EXISTS (
    SELECT 1 FROM collections c WHERE c.id = collection_id AND c.is_public = true
  ));

-- =============================================================================
-- COLLABORATORS
-- =============================================================================

CREATE TABLE IF NOT EXISTS collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  collaborator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scope TEXT NOT NULL CHECK (scope IN ('account', 'collection', 'pen')),
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  pen_id UUID REFERENCES pens(id) ON DELETE CASCADE,
  permission TEXT NOT NULL DEFAULT 'edit' CHECK (permission IN ('edit', 'view')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (
    (scope = 'account' AND collection_id IS NULL AND pen_id IS NULL) OR
    (scope = 'collection' AND collection_id IS NOT NULL AND pen_id IS NULL) OR
    (scope = 'pen' AND pen_id IS NOT NULL AND collection_id IS NULL)
  )
);

ALTER TABLE collaborators ENABLE ROW LEVEL SECURITY;

-- Owner can manage their collaborators
CREATE POLICY collaborators_owner ON collaborators
  FOR ALL TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Collaborators can see grants given to them
CREATE POLICY collaborators_self_read ON collaborators
  FOR SELECT TO authenticated
  USING (auth.uid() = collaborator_id);

-- =============================================================================
-- SECURITY DEFINER FUNCTIONS
-- =============================================================================

-- Check if a user can edit a specific pen (checks all three scopes)
CREATE OR REPLACE FUNCTION can_edit_pen(check_user_id UUID, check_pen_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM collaborators
    WHERE collaborator_id = check_user_id
      AND permission = 'edit'
      AND (
        -- Account-level: owner granted access to all pens
        (scope = 'account' AND owner_id = (SELECT user_id FROM pens WHERE id = check_pen_id))
        -- Collection-level: pen is in a collection they have access to
        OR (scope = 'collection' AND collection_id IN (
          SELECT cp.collection_id FROM collection_pens cp WHERE cp.pen_id = check_pen_id
        ))
        -- Pen-level: direct grant
        OR (scope = 'pen' AND pen_id = check_pen_id)
      )
  );
END;
$$;

-- Look up a user by email (for collaborator invites)
CREATE OR REPLACE FUNCTION lookup_user_by_email(lookup_email TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  found_id UUID;
BEGIN
  SELECT id INTO found_id FROM auth.users WHERE email = lookup_email LIMIT 1;
  RETURN found_id;
END;
$$;

-- Look up multiple users by IDs (for displaying collaborator emails)
CREATE OR REPLACE FUNCTION lookup_users_by_ids(user_ids UUID[])
RETURNS TABLE(id UUID, email TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY SELECT au.id, au.email::TEXT FROM auth.users au WHERE au.id = ANY(user_ids);
END;
$$;

-- =============================================================================
-- UPDATED RLS POLICIES ON PENS (add collaborator access)
-- =============================================================================

-- Authenticated users can SELECT pens they own OR have been granted access to
-- (This replaces the original owner-only SELECT policy)
-- DROP POLICY IF EXISTS pens_select ON pens;
-- CREATE POLICY pens_select ON pens FOR SELECT TO authenticated
--   USING (auth.uid() = user_id OR can_edit_pen(auth.uid(), id));

-- Authenticated users can UPDATE pens they own OR have been granted edit access to
-- DROP POLICY IF EXISTS pens_update ON pens;
-- CREATE POLICY pens_update ON pens FOR UPDATE TO authenticated
--   USING (auth.uid() = user_id OR can_edit_pen(auth.uid(), id));

-- Anon can read public pens (direct or via public collection)
-- DROP POLICY IF EXISTS anon_pens_select ON pens;
-- CREATE POLICY anon_pens_select ON pens FOR SELECT TO anon
--   USING (
--     is_public = true
--     OR id IN (SELECT cp.pen_id FROM collection_pens cp JOIN collections c ON c.id = cp.collection_id WHERE c.is_public = true)
--   );

-- =============================================================================
-- PROFILE COLUMNS FOR PUBLIC SHARING
-- =============================================================================

-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS collection_public BOOLEAN NOT NULL DEFAULT false;
-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS share_slug TEXT UNIQUE;

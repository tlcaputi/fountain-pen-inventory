# Fountain Pen Inventory — Implementation Plan

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | SvelteKit + Svelte 5 + `adapter-static` | Compiles to static HTML for GitHub Pages; minimal runtime; excellent DX for form-heavy UIs |
| CSS | Tailwind CSS v4 (`@tailwindcss/vite`) | CSS-first config, sub-50ms HMR, built-in container queries, tiny bundles |
| Components | shadcn-svelte (Bits UI primitives) | Accessible, customizable, copy-paste components; includes Data Table (TanStack Table) |
| Backend | Supabase (PostgreSQL + Auth + Edge Functions) | Managed Postgres, built-in auth, RLS for multi-tenancy |
| Photo Storage | Cloudflare R2 | 10 GB free (vs 1 GB Supabase), zero egress fees, S3-compatible |
| Hosting | GitHub Pages | Free, simple, works with adapter-static |
| Fonts | Inter (UI) + Lora (display headings) | Clean data UI + premium serif feel for a collector app |

## Credentials & Endpoints

| Item | Value |
|------|-------|
| Supabase URL | `https://dbrfpmrngreaqoggamfx.supabase.co` |
| Supabase Publishable Key | `sb_publishable_qsPZ-YBrbZnkFLV6luWbew_o-0D6aNx` |
| R2 Account ID | `bab65d566ec91f24744655e2543428ab` |
| R2 S3 Endpoint | `https://bab65d566ec91f24744655e2543428ab.r2.cloudflarestorage.com` |
| R2 Bucket | `fpi-uploads` |
| R2 Public URL | `https://pub-e0a99e8fcc0747c9968d29317d1cad48.r2.dev` |
| R2 Access Key ID | Stored as Supabase Edge Function secret (never in frontend code) |
| R2 Secret Access Key | Stored as Supabase Edge Function secret (never in frontend code) |
| GitHub Username | `tlcaputi` |
| Seed User | `tcaputi@gmail.com` / `password` (dev only — change before production) |
| Auth Email | Supabase built-in (2/hour limit; upgrade to Resend/SendGrid for production) |
| OAuth | None for v1 (email/password only) |
| Domain | `pens.bankbonimus.com` |
| DNS Provider | IONOS (API credentials in `bankbonimus.com/.ionos-credentials`) |
| DNS API | `https://api.hosting.ionos.com/dns/v1/zones` |

---

## Testing & Quality Strategy

Every phase includes verification steps. The pattern is:

1. **Functional test** — does the feature work? (CRUD, auth, uploads, etc.)
2. **Visual audit** — does it look right? (screenshot review of every screen, light + dark mode, desktop + mobile)
3. **Edge case test** — what breaks? (empty states, long text, missing data, network errors, concurrent access)
4. **Iteration** — fix issues found, re-test until clean

Visual audits use this workflow:
1. Serve the app locally (`npm run dev`)
2. Screenshot each screen at desktop (1280px) and mobile (375px) widths, light and dark mode
3. Review screenshots for: alignment, spacing, truncation, overflow, contrast, font rendering, responsive breakpoints
4. Fix issues and re-screenshot until clean

---

## Phase 0: Project Scaffolding

### Build
1. **Create GitHub repo** — `tlcaputi/fountain-pen-inventory`, public
2. **Init SvelteKit project** with Svelte 5, TypeScript, Tailwind CSS v4
3. **Install shadcn-svelte** and add base components (Button, Card, Dialog, Input, Select, Tabs, Table, Toast/Sonner, Command, Sheet, Combobox)
4. **Configure adapter-static** with `fallback: '404.html'` for SPA routing on GitHub Pages
5. **Set up GitHub Actions** workflow: on push to `main`, build and deploy to `gh-pages` branch
6. **Configure Supabase JS client** — `@supabase/supabase-js`, project URL + publishable key in a config file (not .env, since this is a static site — these are public values)
7. **Set up Supabase CLI** locally — needed for Edge Function deployment and running migrations
8. **Set up custom domain `pens.bankbonimus.com`:**
   - **SAFETY: only ADD a new CNAME record. Do NOT modify or delete any existing DNS records.** Existing sites (`bankbonimus.com`, `theodorecaputi.com`, `tlcaputi.com`) must remain live and unaffected.
   - Add CNAME record via IONOS DNS API: `pens.bankbonimus.com` → `tlcaputi.github.io`
     ```bash
     # Get zone ID for bankbonimus.com
     curl -s -X GET "https://api.hosting.ionos.com/dns/v1/zones" \
       -H "X-API-Key: <prefix>.<secret>"

     # Add CNAME record
     curl -s -X POST "https://api.hosting.ionos.com/dns/v1/zones/<zone-id>/records" \
       -H "X-API-Key: <prefix>.<secret>" \
       -H "Content-Type: application/json" \
       -d '[{"name":"pens.bankbonimus.com","type":"CNAME","content":"tlcaputi.github.io","ttl":3600}]'
     ```
   - Add `CNAME` file to repo root containing `pens.bankbonimus.com`
   - Configure custom domain in GitHub repo Settings → Pages → Custom domain
   - GitHub auto-provisions SSL certificate (may take up to 24 hours)
   - Wait for HTTPS to work before proceeding to auth configuration

### Test
- [ ] `npm run build` succeeds with zero errors
- [ ] `npm run preview` serves the app locally
- [ ] Push to GitHub → Actions workflow runs → site deploys to GitHub Pages
- [ ] `https://pens.bankbonimus.com` loads with valid HTTPS certificate
- [ ] Supabase client initializes without errors (check browser console)
- [ ] DNS propagation complete (`dig pens.bankbonimus.com CNAME` returns `tlcaputi.github.io`)

**Deliverable:** Empty app shell that builds, deploys to `pens.bankbonimus.com`, and connects to Supabase.

---

## Phase 1: Supabase Database & Auth

See `SUPABASE-AUTH.md` for full SQL schemas.

### Build
1. **Write SQL migration** for all tables (must create `inks` before `pen_photos` due to FK):
   - `profiles` — user settings (PK = `auth.users.id`)
   - `pens` — all pen columns + `user_id`
   - `inks` — all ink columns + `user_id`
   - `pen_photos` — `photo_url`, `caption`, `pen_id` FK, `ink_id` FK, `user_id`
   - `ink_recipes` — recipe columns + `user_id`
   - `manufacturers` — name, country, `user_id`
   - `finishes` — finish, abbreviation, `user_id`
   - `currencies` — 11 columns, global (no `user_id`)
   - `links` — URL, name, etc. + `user_id`
   - `changelog` — version history, global, read-only
   - `storage_usage` — file tracking for R2 10 GB cap enforcement
2. **Enable RLS** on every table with `(SELECT auth.uid()) = user_id` policies
3. **Index `user_id`** on all user-scoped tables
4. **Seed data** — 210 currencies, default manufacturers/finishes, changelog entries
5. **Auth trigger** — `handle_new_user()` function: auto-create `profiles` row + seed per-user manufacturers/finishes on signup
6. **Deploy Edge Functions** via Supabase CLI:
   - `upload-url` — validates JWT, checks global cap (10 GB), per-user cap (100 MB), per-file cap (3 MB), reserves space in `storage_usage`, returns presigned R2 PUT URL
   - `delete-photo` — validates JWT, verifies ownership, deletes from R2, removes `storage_usage` row, clears URL from pens/inks table
7. **Set Edge Function secrets** — R2 credentials via `supabase secrets set`
8. **Configure auth in Supabase dashboard:**
   - Site URL: `https://pens.bankbonimus.com`
   - Redirect URLs: `https://pens.bankbonimus.com/**` + `http://localhost:5173/**`
   - Disable email confirmation (for development)
9. **Run migration** — execute SQL via Supabase dashboard SQL Editor or CLI

### Test
- [ ] All tables created successfully — verify in Supabase Table Editor
- [ ] RLS test: create two test users, verify user A cannot see user B's data via Supabase client
- [ ] Signup creates profile row + seeded manufacturers/finishes automatically
- [ ] `upload-url` Edge Function: returns presigned URL for valid JWT, rejects unauthenticated requests
- [ ] `upload-url` Edge Function: rejects upload when global total would exceed 10 GB (simulate by inserting fake `storage_usage` rows summing to 10 GB)
- [ ] `upload-url` Edge Function: rejects upload when user total would exceed 100 MB
- [ ] `upload-url` Edge Function: rejects files > 3 MB
- [ ] `delete-photo` Edge Function: deletes R2 object, removes `storage_usage` row
- [ ] Upload a test image via presigned URL → verify it's accessible at the R2 public URL
- [ ] Currencies table has 210 rows
- [ ] Global tables (currencies, changelog) are readable but not writable by authenticated users

**Deliverable:** Fully configured Supabase backend with auth, RLS, Edge Functions, R2 integration, and seed data.

---

## Phase 1b: Seed User Account & Pen Data

### Build
1. **Create seed user** — `tcaputi@gmail.com` with password `password` via Supabase dashboard (Authentication > Users > Add User) or admin API
2. **Write seed script** (Node.js or Python, run locally once) that:
   - Parses all 17 pen markdown files from `/Users/theo/MIT Dropbox/Theodore Caputi/bankbonimus.com/_pen/*.md`
   - Extracts YAML frontmatter fields:
     - `manufacturer` → `pens.manufacturer`
     - `title` (minus manufacturer prefix) → `pens.model`
     - `year` → `pens.year_made`
     - `filling_system` → `pens.filler`
     - `nib` → `pens.nib_material`
     - `color` → `pens.color`
     - `explanation` → `pens.description`
     - `date_acquired` → `pens.purchase_date` (if non-empty)
     - `price_acquired` → `pens.purchase_price` (if non-empty)
   - Compresses each photo to ~300 KB (max 1200px, JPEG quality 80)
   - Uploads photos to R2 at `{user_id}/{pen_slug}/filename.jpg` via the `upload-url` Edge Function (tests the real upload flow)
   - First gallery image → `pens.photo_closed_url`
   - Remaining images → `pen_photos` table rows
   - Inserts pen records into Supabase `pens` table

### Test
- [ ] All 17 pens appear in the `pens` table with correct field mapping
- [ ] All 140 photos uploaded to R2 and accessible via public URL
- [ ] `storage_usage` table has 140 rows with accurate file sizes
- [ ] `photo_closed_url` populated on each pen with a working image URL
- [ ] Gallery photos linked to correct pens in `pen_photos` table
- [ ] Login as `tcaputi@gmail.com` / `password` → can see all 17 pens via Supabase client query

**Deliverable:** tcaputi@gmail.com account with all 17 pens and 140 photos pre-loaded.

---

## Phase 2: Frontend Shell & Auth UI

### Build
1. **Login page** — email/password form, "Forgot password?" link, "Sign up" link
2. **Signup page** — email, password, first name, last name
3. **Password reset flow** — request page + update page (after email redirect)
4. **Auth state management** — `onAuthStateChange` listener, route guards (redirect to login if unauthenticated), session persistence across tabs
5. **App shell** — collapsible sidebar nav with icons + labels:
   - Pens, Inks, Ink Recipes, Manufacturers, Finishes, Links, Settings
6. **Responsive layout** — persistent sidebar on desktop (lg+), Sheet/drawer on mobile
7. **Dark/light mode toggle** — 3-way (Light / Dark / System), stored in `localStorage`
8. **Command palette** — Cmd+K for quick navigation and search
9. **App-level error boundary** — catch unhandled errors, show friendly message

### Test
- [ ] Login with `tcaputi@gmail.com` / `password` → redirected to app shell
- [ ] Login with wrong password → error message displayed
- [ ] Signup with new email → account created, profile + defaults seeded, redirected to app
- [ ] Logout → redirected to login, cannot access app routes
- [ ] Direct URL access while logged out → redirected to login, then back to intended page after login
- [ ] Password reset email sends (within 2/hour limit)
- [ ] Session persists across page refresh
- [ ] Session syncs across browser tabs (login in one tab → authenticated in other)

### Visual Audit
- [ ] Login page: desktop + mobile, light + dark — clean, centered, no overflow
- [ ] Signup page: same checks
- [ ] App shell: sidebar renders correctly on desktop (lg+), collapses on mobile
- [ ] Sidebar active state highlights current page
- [ ] Dark mode: all text readable, no white flashes on load, correct contrast ratios
- [ ] Command palette opens on Cmd+K, renders correctly, keyboard navigable
- [ ] Theme toggle: switching modes updates immediately, preference persists across refresh

**Deliverable:** Authenticated app shell with navigation, theme toggle, and route guards.

---

## Phase 3: Pens Module — List & Table Views

### Build
1. **Pen List view** — shadcn Data Table (TanStack Table) with:
   - Sortable columns (Manufacturer, Model, Color, Nib, Filler, Purchase Price)
   - Click column header to sort asc/desc
   - Global search bar (searches across manufacturer, model, description, color)
   - Filter: "Show Unsold Only" toggle (excludes pens with `selling_date`)
   - Purchase price subtotal in footer
   - Pen count in footer (auto-excludes sold pens)
   - Column visibility toggle (show/hide columns)
   - Pagination (25/50/100 per page)
   - Row click → navigate to Pen Detail
2. **Pen Table view** — spreadsheet-style grid:
   - All columns visible (horizontally scrollable)
   - Frozen first column (Manufacturer & Model) on scroll
   - Print-friendly CSS
3. **Empty state** — friendly message + "Add your first pen" CTA when collection is empty

### Test
- [ ] All 17 seeded pens appear in the list
- [ ] Sort by each column — ascending and descending both work
- [ ] Search "Waterman" → shows only Waterman pens; clear search → shows all
- [ ] Search for something in description field (e.g., "sterling silver") → finds the pen
- [ ] "Show Unsold Only" toggle works (mark a pen as sold first, verify it disappears)
- [ ] Pen count and purchase price subtotal update correctly with filters
- [ ] Column visibility toggle hides/shows columns
- [ ] Pagination: change page size, navigate pages
- [ ] Click a row → navigates to pen detail (Phase 4, can be stub for now)
- [ ] Table view: horizontal scroll works, first column stays frozen

### Visual Audit
- [ ] Desktop (1280px): table fills available width, columns proportioned well, no horizontal scroll needed for default columns
- [ ] Mobile (375px): table converts to card layout or scrolls gracefully — no broken layout
- [ ] Dark mode: table headers, borders, hover states all correct
- [ ] Empty state: shows when no pens match filter, looks inviting not broken
- [ ] Search bar: properly styled, placeholder text visible, clear button works
- [ ] Footer: pen count + subtotal aligned, readable
- [ ] Print: table prints cleanly (test Cmd+P → print preview)
- [ ] Long pen names / descriptions: truncate with ellipsis, don't break layout
- [ ] Pen with no photo: placeholder/fallback image in thumbnail column

**Deliverable:** Browsable, searchable, sortable pen collection views.

---

## Phase 4: Pens Module — Detail/Edit View

### Build
1. **Form layout** — organized into tabbed sections:
   - **Overview** — Model, Manufacturer (combobox), Description, Pen Type, Year Made, Color
   - **Physical** — Primary Material, Body Material, Size, Length, Length Posted, Diameter, Weight, Cap Type
   - **Nib & Filling** — Nib Stroke, Material, Flex, Modification, Filler type
   - **Purchase & Sale** — Purchase Price + Currency (combobox from 210 currencies), Purchase Date, Purchased From, Shipping, Retail Price, Selling Price/Date/Sold To/Traded For, Current Value, Valuation Date
   - **Condition** — Condition Rating, New/Used, Repair Required/Cost/Repaired By
   - **Misc** — Miscellaneous notes, Comments
2. **Manufacturer & Model header** — auto-computed, displayed prominently at top (Lora serif)
3. **Multi-currency** — currency selector on purchase price, auto-convert to user's preferred currency using exchange rate from `currencies` table; display both original and converted amounts
4. **Computed fields** — Total Pens in Collection, record position ("Pen X of Y")
5. **CRUD**:
   - Create: "New Pen" button (from list view or nav)
   - Read: load pen data on route entry
   - Update: explicit Save button (not auto-save, to avoid accidental changes)
   - Delete: confirmation dialog ("Are you sure? This cannot be undone.")
6. **Previous/Next navigation** — arrows to step through pens in current sort/filter order
7. **Sticky save bar** — fixed at bottom with Save / Cancel / Delete, visible while scrolling

### Test
- [ ] Load a seeded pen → all fields populated correctly
- [ ] Edit a field, click Save → field persists on page reload
- [ ] Edit a field, click Cancel → changes reverted
- [ ] Create new pen → appears in list, navigates to detail
- [ ] Delete a pen → confirmation dialog → pen removed from list and database
- [ ] Manufacturer combobox: type to search, select from list, can add new manufacturer
- [ ] Currency conversion: enter price in GBP → USD equivalent displayed correctly using exchange rate
- [ ] Prev/Next navigation: steps through pens in same order as list view
- [ ] "Pen X of Y" counter updates correctly
- [ ] Navigate away with unsaved changes → warn user (browser beforeunload or custom dialog)

### Visual Audit
- [ ] Desktop: form is well-organized, tabs clearly delineated, fields aligned in grid
- [ ] Mobile: form stacks to single column, tabs remain usable (horizontal scroll or dropdown)
- [ ] Manufacturer & Model header: Lora font, correct hierarchy, total rating badge
- [ ] Tabs: active tab clearly indicated, content switches smoothly
- [ ] Sticky save bar: always visible at bottom, doesn't overlap form content (scroll-padding)
- [ ] Combobox dropdowns: positioned correctly, don't clip behind other elements
- [ ] Empty fields: show placeholder text, don't look broken
- [ ] Long description text: textarea grows or scrolls, doesn't overflow
- [ ] Currency display: both original and converted price shown clearly
- [ ] Dark mode: all form elements (inputs, selects, textareas) correctly themed

**Deliverable:** Full pen detail form with all fields, multi-currency support, CRUD operations.

---

## Phase 5: Pen Reviews & Ratings

### Build
1. **Review editor** — tabbed or accordion layout with 7 sections:
   - First Impression (+ rating) — with prompt text
   - Appearance (+ rating) — with prompt text
   - Design/Size/Weight (+ rating) — with prompt text
   - Nib (+ rating) — with prompt text
   - Filling System (+ rating) — with prompt text
   - Cost & Value (+ rating) — with prompt text
   - Conclusion (text only, no rating)
2. **Rating widget** — 1–10 numeric input (clickable segments or number input with gold accent)
3. **Total Rating** — auto-computed average of the 6 category ratings (only counts non-null ratings), displayed prominently
4. **Review-to-clipboard** — button that compiles:
   - All review sections with headers
   - All ratings
   - FPN Username attribution
   - Formatted as BBCode (for FPN forum posting)
   - Copies to clipboard with toast confirmation
5. **Prompt text** — each section shows the original FPI prompt as helper text (from `fpn-features.md`)

### Test
- [ ] Write text in each review section → saves correctly
- [ ] Set ratings 1–10 for each category → total auto-computes as average
- [ ] Set only 3 of 6 ratings → total averages the 3, not all 6
- [ ] Clear all ratings → total shows as empty/null
- [ ] "Copy Review to Clipboard" → paste into text editor → correct BBCode format with:
  - `[b]First Impression[/b]` headers
  - Rating values
  - FPN Username at bottom
- [ ] Toast appears: "Review copied to clipboard"
- [ ] Review-to-clipboard with empty sections → skips empty sections gracefully

### Visual Audit
- [ ] Review tabs/accordion: clear section delineation, prompt text visible but subtle
- [ ] Rating widget: gold accent color, clear which number is selected, clickable on mobile
- [ ] Total Rating: prominently displayed, updates in real-time as ratings change
- [ ] Textareas: generous size for review writing, resize handle
- [ ] Desktop + mobile: review editor usable on both, textareas don't squeeze too narrow on mobile
- [ ] Dark mode: all review elements correctly themed

**Deliverable:** Structured review editor with ratings and clipboard export.

---

## Phase 6: Photo System

### Build
1. **Inline photos** — 5 structured slots on pen detail:
   - Photo Closed, Photo Open, Photo Posted, Photo Nib, Photo Converter
   - Each with caption field
   - Click to upload (drag-and-drop zone) or click existing photo to view/replace/delete
   - Client-side compression (browser-image-compression: max 1200px, quality 80, target ~300 KB)
   - Upload flow: request presigned URL from Edge Function → PUT to R2 → save URL to `pens` table
   - Progress indicator during upload
2. **Big Photo view** — lightbox/modal:
   - Opens on photo click
   - Slideshow arrows to navigate the 5 inline photos
   - Caption displayed below
   - Keyboard navigation (arrow keys, Escape)
   - Pinch-to-zoom on mobile, scroll-to-zoom on desktop
3. **Gallery photos** — unlimited additional photos via `pen_photos` table:
   - Grid layout below inline photos
   - Add button → same upload flow as inline
   - Delete button per photo (with confirmation)
   - Edit caption inline
   - Optional ink cross-link (combobox to select which ink is shown in the photo)
4. **Ink photos** — single main photo + caption on each ink record (same upload flow)

### Test
- [ ] Upload a photo to "Photo Closed" slot → image appears, URL saved to `pens.photo_closed_url`
- [ ] Upload to all 5 inline slots → all display correctly
- [ ] Replace an existing inline photo → old one deleted from R2, new one uploaded, URL updated
- [ ] Delete an inline photo → removed from R2, URL cleared, slot shows empty state
- [ ] Upload a gallery photo → appears in grid, row created in `pen_photos`
- [ ] Delete a gallery photo → removed from R2 and `pen_photos`
- [ ] Edit gallery photo caption → saves correctly
- [ ] Lightbox: click photo → opens full-size, arrows navigate between photos, Escape closes
- [ ] Lightbox keyboard: left/right arrows work, Escape closes
- [ ] Upload a 10 MB photo → client-side compression reduces it → upload succeeds
- [ ] Upload when user is at 100 MB limit → Edge Function rejects with clear error message
- [ ] Upload when global storage is at 10 GB → Edge Function rejects with clear error message
- [ ] Upload non-image file (e.g., .pdf) → rejected (R2 MIME type restriction or client-side check)
- [ ] `storage_usage` table accurately reflects all uploads and deletions
- [ ] Seeded photos from Phase 1b display correctly in both inline slots and gallery

### Visual Audit
- [ ] Inline photo slots: 5 containers in a row on desktop, wrap on mobile
- [ ] Empty slots: dashed border, camera icon, "Add photo" label — inviting, not broken
- [ ] Filled slots: photo thumbnail with hover overlay (view/replace/delete actions)
- [ ] Upload progress: visible indicator (progress bar or spinner)
- [ ] Lightbox: dark overlay, large image, caption below, navigation arrows visible
- [ ] Gallery grid: uniform or masonry layout, no gaps, add button consistent with style
- [ ] Photos with different aspect ratios: handled gracefully (object-fit: cover or similar)
- [ ] Dark mode: photo borders, overlay, lightbox all correct
- [ ] Mobile: lightbox swipe navigation works, photos don't overflow screen

**Deliverable:** Dual photo system (structured inline + unlimited gallery) with lightbox.

---

## Phase 7: Inks Module

### Build
1. **Inks List** — same Data Table pattern as pens:
   - Columns: Ink Name, Manufacturer, Color Category, Overall Rating, Purchase Price
   - Search, sort, filter, pagination
2. **Ink Detail/Edit** — form with all 31 fields:
   - **Identity** — Ink Name, Manufacturer (combobox), FPN Color Category
   - **Properties** — Color Description, Special Features, Drying Speed, Opacity, Waterproof Rating, Feathering, pH, Sunlight Resistance, Saturation, Shading, Sample/Bottle/Mix, Do Not Mix
   - **Ratings** — Color Rating, Overall Rating
   - **Purchase** — same multi-currency pattern as pens
   - **Photo** — main photo upload + caption (same R2 upload flow)
   - **Notes** — Bottle Volume, Bottle Notes, general Notes
3. **Ink-pen cross-reference** — gallery photos on pens can link to an ink via `pen_photos.ink_id`

### Test
- [ ] CRUD operations: create, read, update, delete inks
- [ ] All 31 fields save and load correctly
- [ ] Manufacturer combobox shares the same manufacturer list as pens
- [ ] Photo upload works (same flow as pen photos)
- [ ] Currency conversion works for ink purchase prices
- [ ] Ink-pen cross-reference: link a pen gallery photo to an ink → ink_id populated in pen_photos
- [ ] Empty state: "No inks yet" message when collection is empty

### Visual Audit
- [ ] Ink list: consistent with pen list styling
- [ ] Ink detail form: same tab/section pattern as pen detail, all fields laid out cleanly
- [ ] Ink properties section: 12 property fields in a logical grid layout
- [ ] Desktop + mobile: responsive at all breakpoints
- [ ] Dark mode: all elements correct

**Deliverable:** Complete ink tracking with scientific properties, ratings, and purchase info.

---

## Phase 8: Ink Recipes

### Build
1. **Recipes list** — CRUD table with Name, Color Description, FPN Color Category, Date Created
2. **Recipe detail** — form with Name, Recipe (textarea), Color Description, Notes, FPN Color Category, dates
3. **Sort selector** — user-selectable sort field (name, date, color category)
4. **Embedded view** — show recipes as a sub-panel within ink detail (portal style, matching original FPI)

### Test
- [ ] CRUD: create, read, update, delete recipes
- [ ] Sort by name, date, color category — all work
- [ ] Recipes embedded in ink detail: display correctly, can add/edit from within ink view
- [ ] Date fields auto-populate on create, update on edit

### Visual Audit
- [ ] Recipe list: consistent styling with other list views
- [ ] Recipe detail form: clean layout, textarea for recipe instructions is generous
- [ ] Embedded in ink detail: visually distinct sub-panel, doesn't clash with ink form
- [ ] Desktop + mobile + dark mode

**Deliverable:** Ink recipe management with sorting and ink-detail embedding.

---

## Phase 9: Reference Tables

### Build
1. **Manufacturers** — CRUD list (name, country); feeds combobox on Pens and Inks; per-user, seeded from defaults
2. **Finishes** — CRUD list (finish name, abbreviation); per-user, seeded from defaults
3. **Links** — CRUD directory (URL, name, description, type dropdown, valid flag, total count); per-user
4. **Currencies** — read-only table (210 currencies with symbol, country, ISO code, exchange rate); global; search/filter
5. **Changelog** — read-only list (version, date, change description); global

### Test
- [ ] Manufacturers CRUD: add, edit, delete; new manufacturer appears in pen/ink comboboxes
- [ ] Finishes CRUD: add, edit, delete
- [ ] Links CRUD: add, edit, delete; URL field validation; type dropdown works
- [ ] Currencies: all 210 display, search by country/currency name works, read-only (no edit/delete buttons)
- [ ] Changelog: displays entries, read-only
- [ ] Deleting a manufacturer that's in use by a pen → pen retains the manufacturer string (no cascade deletion of pen data)

### Visual Audit
- [ ] All reference table screens: consistent list styling
- [ ] Add/edit forms: modal dialogs (simple enough for modal, not full-page)
- [ ] Currencies table: 210 rows render efficiently, search is responsive
- [ ] Desktop + mobile + dark mode

**Deliverable:** All reference table CRUD screens.

---

## Phase 10: Settings & Profile

### Build
1. **User Profile form** — First Name, Last Name, Address (1 & 2), City, State, Province, Zip, Country, Phone, Email
2. **FPN Username** — for review attribution
3. **Preferred Currency** — combobox from currencies table; changing this updates all localized price displays across the app
4. **Photo Folder URL** — optional web directory for photo hosting
5. **Account actions** — change password, sign out
6. **App info** — version number, link to changelog

### Test
- [ ] Edit profile fields → save → persist on reload
- [ ] Change preferred currency → localized prices update on pen and ink detail pages
- [ ] Change FPN Username → review-to-clipboard uses new username
- [ ] Change password → can login with new password, old password rejected
- [ ] Sign out → redirected to login

### Visual Audit
- [ ] Settings page: clean form layout, single column, grouped sections
- [ ] Currency combobox: searchable, shows currency name + code + symbol
- [ ] Desktop + mobile + dark mode

**Deliverable:** User settings screen with profile, currency preference, and account management.

---

## Phase 11: Search, Sort & Keyboard Shortcuts

### Build
1. **Global search** — Cmd/Ctrl+F opens find mode:
   - Search across any field on current view (pens or inks)
   - Results filtered in real-time
2. **Sort dialog** — Cmd/Ctrl+S opens multi-field sort picker:
   - Add sort fields with asc/desc toggle
   - Stack multiple sort levels
   - Apply / Clear sort
3. **Keyboard shortcuts**:
   - Cmd/Ctrl+N — new record
   - Cmd/Ctrl+K — command palette
   - Cmd/Ctrl+F — find/search
   - Cmd/Ctrl+S — sort dialog (override browser save — only on list views)
   - Left/Right arrows — previous/next record (in detail view only)
   - Escape — close modal/dialog/lightbox
4. **"Show Unsold Pens"** — toggle filter (exclude pens with selling_date)

### Test
- [ ] Cmd+F on pen list → search bar focuses, typing filters results
- [ ] Cmd+S on pen list → sort dialog opens, can add multiple sort fields
- [ ] Multi-level sort: sort by manufacturer asc, then by model asc → correct order
- [ ] Cmd+N → navigates to new pen form
- [ ] Cmd+K → command palette opens, can type to navigate or trigger actions
- [ ] Arrow keys in detail view → prev/next pen
- [ ] Escape closes all modals, dialogs, lightbox, command palette
- [ ] Cmd+S on detail view → does NOT open sort dialog (only on list views); consider: should it save the form?
- [ ] Shortcuts don't fire when typing in a text input/textarea

### Visual Audit
- [ ] Sort dialog: clean modal with add/remove sort fields, clear visual feedback
- [ ] Command palette: centered overlay, search input, keyboard-navigable results list
- [ ] Desktop + mobile + dark mode

**Deliverable:** Power-user search, sort, and keyboard shortcuts matching original FPI.

---

## Phase 12: Integration Testing & Polish

### Full Feature Audit Against `fpn-features.md`

Walk through every feature documented in `fpn-features.md` and verify:

- [ ] **Pen tracking (Section 2):** all 78 columns mapped and functional
- [ ] **Rating system (Section 3):** 8 rating fields, total auto-computed
- [ ] **Photo management (Section 4):** 5 inline + unlimited gallery, lightbox with slideshow
- [ ] **Ink tracking (Section 5):** all 31 columns, 12 scientific properties
- [ ] **Ink recipes (Section 6):** CRUD, embedded in ink detail
- [ ] **Manufacturers (Section 7.1):** CRUD, feeds dropdowns
- [ ] **Finishes (Section 7.2):** CRUD with abbreviations
- [ ] **Currencies (Section 7.3):** 210 currencies, localized price conversion
- [ ] **Links (Section 7.4):** CRUD directory with type and valid flag
- [ ] **User profile (Section 8):** all fields, currency preference, FPN username
- [ ] **Changelog (Section 9):** read-only display
- [ ] **All screens (Section 10.1):** Record View, Reviews, List View, Table View, Big Photo, Inks, Manufacturers, Finishes, Links, Settings
- [ ] **Menus & shortcuts (Section 10.2):** Sort, Find, Show Unsold Pens
- [ ] **Workflows (Section 10.3):** Adding a pen, writing a review, selling a pen, multi-currency purchase, photo management

### Cross-Browser Testing

- [ ] Chrome (latest) — desktop + mobile
- [ ] Safari (latest) — desktop + iOS
- [ ] Firefox (latest) — desktop

### Responsive Testing (Every Screen)

For each screen (login, pen list, pen detail, pen review, photo gallery, ink list, ink detail, recipes, manufacturers, finishes, links, currencies, changelog, settings):

- [ ] Desktop 1280px — light + dark
- [ ] Tablet 768px — light + dark
- [ ] Mobile 375px — light + dark

That's **14 screens × 3 breakpoints × 2 themes = 84 visual checks.** Take screenshots, review for:
- Alignment and spacing
- Text truncation / overflow
- Touch target sizes (minimum 24×24px)
- Readable contrast ratios
- No horizontal scroll on mobile (except table view)

### Accessibility Audit

- [ ] All form fields have visible labels (not placeholder-only)
- [ ] All icon-only buttons have `aria-label`
- [ ] Heading hierarchy: h1 > h2 > h3, no skipping
- [ ] Skip-to-content link present
- [ ] Focus visible on all interactive elements
- [ ] Focus not obscured by sticky headers/save bar
- [ ] Color is never the sole indicator of state
- [ ] All interactive targets ≥ 24×24px
- [ ] Keyboard navigation: Tab through entire app, everything reachable
- [ ] Screen reader test (VoiceOver on macOS): key flows (login, browse pens, add pen, write review)

### Performance

- [ ] Lighthouse audit: target 90+ on Performance, Accessibility, Best Practices
- [ ] Photos lazy-load (below-the-fold images don't load until scrolled into view)
- [ ] Bundle size check: JS bundle < 200 KB gzipped
- [ ] Time to interactive < 2s on desktop, < 3s on mobile

### Error Handling

- [ ] Network offline → graceful error messages, no blank screens
- [ ] Supabase auth token expired → auto-refresh or redirect to login
- [ ] R2 upload fails → clear error message, retry option
- [ ] Supabase query fails → error message with retry, not a blank screen
- [ ] Storage quota exceeded → clear message explaining the limit

### Print Styles

- [ ] Pen detail prints as clean single-column layout (hide sidebar, nav, save bar)
- [ ] Pen list prints as simple table
- [ ] Photos at reasonable size (max 300px width)
- [ ] Page breaks between pen records

### Security Review

- [ ] No API keys or secrets in frontend source code (only publishable key)
- [ ] RLS policies prevent cross-user data access
- [ ] R2 credentials only in Edge Function secrets
- [ ] No XSS vectors in user-generated content (review text, descriptions, URLs)
- [ ] Link URLs displayed but not auto-executed as HTML

### Final Items

- [ ] Lock down R2 CORS: replace `*` origin with `https://pens.bankbonimus.com` + `http://localhost:5173`
- [ ] Update seed user password from `password` to something secure (or document that it must be changed)
- [ ] Favicon and app title set
- [ ] Open Graph / meta tags for sharing (title: "Fountain Pen Inventory", description, preview image)
- [ ] 404 page: friendly message with link back to app
- [ ] `pens.bankbonimus.com` loads with valid HTTPS, no mixed content warnings
- [ ] All auth flows work on the custom domain (signup, login, password reset redirects)

**Deliverable:** Production-ready, polished, accessible, tested web application.

---

## Phase Dependencies

```
Phase 0 (Scaffold) ──→ Phase 1 (DB & Auth) ──→ Phase 1b (Seed Data)
                                                        │
                                                        ▼
                                                Phase 2 (Shell & Auth UI)
                                                        │
                          ┌─────────────────────────────┤
                          ▼                             ▼
                   Phase 3 (Pen List)            Phase 9 (Reference Tables)
                          │
                          ▼
                   Phase 4 (Pen Detail)
                          │
                   ┌──────┴──────┐
                   ▼             ▼
            Phase 5 (Reviews)  Phase 6 (Photos)
                   │             │
                   └──────┬──────┘
                          ▼
                   Phase 7 (Inks) ──→ Phase 8 (Recipes)
                          │
                          ▼
                   Phase 10 (Settings)
                          │
                          ▼
                   Phase 11 (Search/Sort/Keys)
                          │
                          ▼
                   Phase 12 (Integration Testing & Polish)
```

- Phases 3 and 9 can run in parallel after Phase 2
- Phases 5 and 6 can run in parallel after Phase 4
- Phase 12 is cumulative — many checks can start as soon as their phase completes, but the full audit happens at the end

# Fountain Pen Inventory — Web Rebuild

## Purpose

Recreate the classic Fountain Pen Inventory (FPI) desktop application as a modern, multi-user web application. The original FPI was a FileMaker Pro Runtime app by Jon Rosen (jonro) used by ~4,000 fountain pen collectors worldwide. This project brings it to the web so collectors can access their inventory from any device.

## Feature Specification

See `fpn-features.md` for the complete feature specification. That document covers:
- All 10 database tables (78 columns on Fountain Pens alone, 31 on Inks)
- 8-dimension rating system and 6 structured review sections with prompts
- Dual photo system (5 structured inline slots + unlimited gallery)
- Multi-currency support (210 currencies with exchange rates)
- Ink tracking with scientific properties (pH, opacity, waterproofness, etc.)
- Ink recipes, manufacturers, finishes, links, user profile/settings
- All UI screens, menus, keyboard shortcuts, and workflows
- Review-to-clipboard feature for FPN forum posting

**The rebuilt app must implement every feature described in fpn-features.md with zero feature loss.**

## Tech Stack

- **Frontend**: Static site hosted on GitHub Pages (HTML/CSS/JS or a JS framework that builds to static)
- **Backend/Database**: Supabase (PostgreSQL + Auth + Storage)
  - Supabase Auth for user accounts (email/password, optional OAuth)
  - Supabase PostgreSQL for all data tables
  - Supabase Storage for photo uploads
  - Supabase Row-Level Security (RLS) so each user can only see their own data
- **Deployment**: GitHub Pages for the frontend, Supabase cloud for the backend

## Architecture

### Database (Supabase PostgreSQL)

Map the 10 FileMaker tables to PostgreSQL tables, all scoped to the authenticated user via RLS:

- `profiles` (user settings — replaces Interface table): user_id (FK to auth.users), first_name, last_name, address, city, state, province, zip, country, phone, email, fpn_username, photo_folder_url, preferred_currency
- `pens` (replaces Fountain Pens): all 78 columns mapped to PostgreSQL types, plus user_id
- `pen_photos` (replaces Photos): photo_url (Supabase Storage path), caption, pen_id (FK), ink_id (FK), user_id
- `inks`: all 31 columns, plus user_id
- `ink_recipes`: name, recipe, color_description, notes, fpn_color_category, dates, user_id
- `manufacturers`: name, country, user_id (each user maintains their own list, seeded from defaults)
- `finishes`: finish, abbreviation, user_id
- `currencies`: currency_symbol, country, currency, value_in_dollars, iso_code, etc. (shared/global table, not per-user)
- `links`: url, name, description, type, valid, user_id
- `changelog`: version, date, change (global, read-only)

### Authentication

- Supabase Auth with email/password signup
- RLS policies on every table: `auth.uid() = user_id`
- New users get seeded with default manufacturers, finishes, and currencies

### Photo Storage

- Supabase Storage bucket per user (or shared bucket with user_id path prefix)
- 5 structured photo slots on each pen (stored as URLs in the pens table)
- Unlimited gallery photos via pen_photos table
- Client-side image compression before upload

### Frontend

- Single-page app feel with client-side routing
- Screens matching the original FPI layouts:
  1. **Pen List** (table/grid view with sortable columns, search, filter unsold)
  2. **Pen Detail/Edit** (form view with all fields, inline photos, purchase/sale info)
  3. **Pen Review** (structured review editor with prompts, ratings, copy-to-clipboard)
  4. **Photo Gallery** (big photo view with slideshow navigation)
  5. **Inks List + Detail** (same pattern as pens)
  6. **Ink Recipes** (embedded in ink detail, or separate view)
  7. **Manufacturers** (CRUD list)
  8. **Finishes** (CRUD list)
  9. **Links** (CRUD directory)
  10. **Settings** (user profile, currency preference, FPN username)
- Keyboard shortcuts matching original (Ctrl/Cmd+S for sort, Ctrl/Cmd+F for find)
- Multi-currency price entry with automatic conversion
- Review-to-clipboard formatting (BBCode for FPN forum posts)
- Responsive design (works on desktop + mobile)

## Domain

TBD — could be `fpi.bankbonimus.com` or a standalone domain.

## Non-Goals (for v1)

- Real-time collaboration / shared collections
- Mobile native apps
- Automated exchange rate updates (manual or periodic is fine)
- FPN forum API integration (clipboard copy is sufficient)

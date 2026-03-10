# Fountain Pen Inventory — Design System

## Design Philosophy

This is a **premium collector's tool**, not a generic CRUD app. The design should evoke the feel of fine stationery and craftsmanship — clean, warm, restrained, with just enough personality to feel special. Think: a well-organized writing desk, not a spreadsheet.

**Principles:**
1. **Functional minimalism** — every element earns its place; no decoration for its own sake
2. **Warm and refined** — warm neutrals, serif accents, gold touches signal quality
3. **Data-dense but not cluttered** — progressive disclosure keeps complexity manageable
4. **Keyboard-first, touch-friendly** — power users get shortcuts; mobile users get gestures

---

## Color Palette

### Light Mode

| Token | Hex | Usage |
|-------|-----|-------|
| `--background` | `#FAFAF8` | Page background (warm white) |
| `--foreground` | `#1A1A1A` | Primary text (near-black) |
| `--card` | `#FFFFFF` | Card/panel backgrounds |
| `--card-foreground` | `#1A1A1A` | Card text |
| `--primary` | `#1E3A5F` | Primary actions, links (deep ink blue) |
| `--primary-foreground` | `#FFFFFF` | Text on primary |
| `--secondary` | `#F0EDE8` | Secondary backgrounds (warm gray) |
| `--secondary-foreground` | `#3D3D3D` | Secondary text |
| `--accent` | `#D4AF37` | Highlights, ratings, premium touches (gold) |
| `--accent-foreground` | `#1A1A1A` | Text on accent |
| `--muted` | `#E8E4DE` | Disabled elements, borders |
| `--muted-foreground` | `#737373` | Placeholder text, captions |
| `--destructive` | `#B91C1C` | Delete actions, errors |
| `--destructive-foreground` | `#FFFFFF` | Text on destructive |
| `--success` | `#15803D` | Confirmation, success states |
| `--border` | `#E0DCD6` | Default borders |
| `--input` | `#E0DCD6` | Input borders |
| `--ring` | `#1E3A5F` | Focus rings |

### Dark Mode

| Token | Hex | Usage |
|-------|-----|-------|
| `--background` | `#121210` | Page background (warm dark) |
| `--foreground` | `#E8E4DE` | Primary text |
| `--card` | `#1C1C1A` | Card/panel backgrounds |
| `--card-foreground` | `#E8E4DE` | Card text |
| `--primary` | `#4A8AC7` | Primary actions (lighter ink blue) |
| `--primary-foreground` | `#FFFFFF` | Text on primary |
| `--secondary` | `#2A2A28` | Secondary backgrounds |
| `--secondary-foreground` | `#C4C0BA` | Secondary text |
| `--accent` | `#D4AF37` | Gold accent (same in both modes) |
| `--accent-foreground` | `#1A1A1A` | Text on accent |
| `--muted` | `#3D3D3A` | Disabled elements |
| `--muted-foreground` | `#8A8A85` | Placeholder text |
| `--destructive` | `#DC2626` | Delete/error |
| `--border` | `#3D3D3A` | Borders |

**Rule:** never use pure black (`#000000`) in dark mode — it causes eye strain.

---

## Typography

### Font Stack

| Role | Font | Fallback |
|------|------|----------|
| **UI / Body** | Inter | system-ui, sans-serif |
| **Display / Headings** | Lora | Georgia, serif |

Inter handles all data, forms, tables, and navigation. Lora adds warmth and prestige to page titles and pen names — a serif font feels right for a fountain pen app.

### Type Scale (1.2 ratio, 4px-aligned)

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `text-xs` | 12px | 400 | Captions, metadata, timestamps |
| `text-sm` | 14px | 400 | Table cells, form labels, secondary text |
| `text-base` | 16px | 400 | Body text, form inputs |
| `text-lg` | 18px | 500 | Section headings within forms |
| `text-xl` | 20px | 600 | Card titles, pen names in list view |
| `text-2xl` | 24px | 600 | Page section headings |
| `text-3xl` | 30px | 700 | Page titles (Lora) |
| `text-4xl` | 36px | 700 | Hero text, pen name in detail view (Lora) |

### Rules

- **Line height:** 1.5 for body, 1.2–1.3 for headings
- **Line length:** 45–85 characters max for readability
- **Contrast:** minimum 4.5:1 for body text, 3:1 for large text (WCAG AA)

---

## Spacing

**Base unit:** 4px. **Primary scale:** 8px increments.

| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | 4px | Tight gaps (icon-to-text, between related items) |
| `--space-2` | 8px | Default gap between small elements |
| `--space-3` | 12px | Padding inside compact components |
| `--space-4` | 16px | Default component padding, form field gaps |
| `--space-5` | 20px | Between form sections |
| `--space-6` | 24px | Card padding, section margins |
| `--space-8` | 32px | Between major sections |
| `--space-10` | 40px | Page-level margins |
| `--space-12` | 48px | Large section separators |
| `--space-16` | 64px | Hero spacing |

---

## Layout

### Breakpoints (Tailwind defaults)

| Name | Width | Layout |
|------|-------|--------|
| `sm` | 640px | Single column, stacked cards |
| `md` | 768px | Two-column forms, wider tables |
| `lg` | 1024px | Sidebar appears (persistent) |
| `xl` | 1280px | Comfortable data tables |
| `2xl` | 1536px | Maximum content width |

### Page Structure

```
┌─────────────────────────────────────────────────┐
│ Header: App title (Lora), theme toggle, user    │
├──────────┬──────────────────────────────────────┤
│          │                                      │
│ Sidebar  │  Main Content Area                   │
│ (nav)    │                                      │
│          │  ┌─ Page Title ─────────────────┐    │
│ Pens     │  │                              │    │
│ Inks     │  │  Content (table, form, etc.) │    │
│ Recipes  │  │                              │    │
│ Mfrs     │  └──────────────────────────────┘    │
│ Finishes │                                      │
│ Links    │                                      │
│ Settings │                                      │
│          │                                      │
├──────────┴──────────────────────────────────────┤
│ Footer (optional): version, pen count, totals   │
└─────────────────────────────────────────────────┘
```

- **Desktop (lg+):** persistent sidebar (collapsible to icon-only), max-width content area
- **Mobile (<lg):** sidebar becomes a Sheet/drawer triggered by hamburger menu
- **Max content width:** 1280px, centered

---

## Component Patterns

### Data Tables (Pen List, Ink List)

- **Headers:** bold, darker background (`--secondary`), sticky on scroll
- **Rows:** subtle hover state (`--secondary` at 50% opacity), click to navigate
- **Borders:** subtle horizontal dividers only (no vertical rules, no zebra striping)
- **Active sort:** chevron indicator on sorted column header
- **Search bar:** above table, full width, with search icon
- **Filter controls:** inline chips/toggles next to search (e.g., "Unsold only")
- **Footer:** pen count + purchase price subtotal
- **Empty state:** illustration + "Add your first pen" button
- **Row density:** comfortable by default (48px row height)
- **Mobile (<md):** convert to card layout — each pen becomes a stacked card with key info (manufacturer, model, color, price)

### Forms (Pen Detail, Ink Detail, Settings)

- **Tabs for sections** — horizontal tabs on desktop, vertical on wide screens
- **Visible labels** on all fields (never placeholder-only)
- **Inline validation** — validate on blur, clear error on input
- **Combobox** for long lists (Manufacturer, Currency) — searchable dropdown
- **Select** for short lists (Nib Stroke, Filling System, Cap Type)
- **Sticky save bar** — fixed at bottom of viewport with Save / Cancel / Delete
- **Progressive disclosure** — sale fields hidden until "Mark as Sold" is toggled; advanced fields behind expandable sections
- **Field grouping** — related fields in visual groups with subtle borders or background

### Modals/Dialogs

- **Confirmation dialogs** — for destructive actions (delete pen, mark as sold)
- **Clear title, close button (X), Escape key, click-outside-to-close**
- **Full-page forms** for complex editing — never put the 78-field pen form in a modal
- shadcn `Dialog` for confirmations, `AlertDialog` for destructive confirmations

### Toasts

- **Position:** bottom-right on desktop, bottom-center on mobile
- **Auto-dismiss:** 4 seconds
- **Use cases:** "Pen saved," "Photo uploaded," "Copied to clipboard," "Filter applied"
- Sonner integration via shadcn-svelte

### Photos

- **Inline photo slots:** 5 rectangular containers in a row on pen detail
  - Empty state: dashed border + camera icon + "Add photo" label
  - Filled state: thumbnail with hover overlay showing caption + "View" / "Replace" / "Delete"
- **Lightbox:** dark overlay, large image, caption below, arrow navigation, keyboard support
- **Gallery grid:** masonry or uniform grid below inline photos, with add button
- **Upload:** drag-and-drop zone with progress indicator, client-side compression feedback

### Ratings

- **Visual:** gold stars or filled circles using `--accent` color
- **Scale:** 1–10 (matching original FPI's likely scale)
- **Interaction:** clickable segments or number input
- **Total Rating:** prominently displayed with larger size, auto-computed

### Sidebar Navigation

- **Icons + labels** — each section has a recognizable icon
- **Active state:** primary color background + bold text
- **Collapse toggle:** icon-only mode on desktop (hover to reveal labels)
- **Mobile:** Sheet component, triggered by hamburger icon

### Command Palette (Cmd+K)

- **Quick navigation:** type to jump to any section (Pens, Inks, Settings)
- **Search:** type pen/ink name to jump directly to that record
- **Actions:** "New Pen," "New Ink," "Toggle Dark Mode"

---

## Specific UI Decisions

### Pen Detail Header

```
┌────────────────────────────────────────────────┐
│  ← Back to List                                │
│                                                │
│  Conway Stewart                    [★ 8.3/10]  │
│  CS388                                         │
│  Blue Marble · Lever · 14KT Gold EF            │
│                                                │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │
│  │Closed│ │ Open │ │Posted│ │ Nib  │ │Conv. │ │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ │
│                                                │
│  [Overview] [Physical] [Nib] [Purchase] [...]  │
│  ──────────────────────────────────────────────│
│  Form fields for active tab...                 │
│                                                │
│                                                │
│  ┌──── Sticky Save Bar ────────────────────┐   │
│  │  [Delete]              [Cancel] [Save]  │   │
│  └─────────────────────────────────────────┘   │
└────────────────────────────────────────────────┘
```

- Manufacturer in `text-2xl` Lora (serif)
- Model in `text-4xl` Lora (serif), bold
- Subtitle line: Color + Filler + Nib summary in `text-sm` muted
- Total Rating badge in top-right with gold accent

### Review Editor

- **Tabbed interface** — one section visible at a time
- **Prompt text** displayed as helper text above each textarea (muted, italic)
- **Rating** next to each section header
- **"Copy Review to Clipboard"** button at bottom — primary style, with clipboard icon
- Toast confirmation: "Review copied to clipboard"

### Multi-Currency Price Entry

```
┌─────────────────┐ ┌──────────────┐
│ 125.00          │ │ GBP ▾        │  ← user enters amount + selects currency
└─────────────────┘ └──────────────┘
  = $157.50 USD                       ← auto-computed in preferred currency
```

---

## Accessibility (WCAG 2.2 AA)

| Requirement | Implementation |
|-------------|---------------|
| **Focus Not Obscured (2.4.11)** | Ensure sticky headers/save bar don't cover focused elements; use `scroll-padding` |
| **Dragging Movements (2.5.7)** | Photo reorder has button alternative (move up/down) |
| **Target Size (2.5.8)** | All interactive targets minimum 24x24px; icon buttons 32x32px |
| **Consistent Help (3.2.6)** | Help link in same sidebar position on every page |
| **Redundant Entry (3.3.7)** | Currency preference auto-applied; don't re-ask for info already provided |
| **Accessible Auth (3.3.8)** | No CAPTCHAs; email/password only |
| **Visible labels** | All form fields have labels (not placeholder-only) |
| **Color not sole indicator** | Status uses icon + color (e.g., "Sold" has icon + red text) |
| **Keyboard navigable** | All elements reachable via Tab, activatable via Enter/Space |
| **Skip navigation** | Skip-to-content link on every page |
| **Heading hierarchy** | h1 > h2 > h3, no skipping levels |
| **ARIA labels** | Icon-only buttons get `aria-label` |

---

## Dark Mode Implementation

1. Define color tokens as CSS custom properties in `:root` and `.dark`
2. Use `@custom-variant dark (&:is(.dark *))` in Tailwind v4
3. Toggle `.dark` class on `<html>` element
4. Three-way toggle: Light / Dark / System
5. Store preference in `localStorage`, fall back to `prefers-color-scheme`
6. Reduce image brightness slightly in dark mode (`filter: brightness(0.9)`)
7. shadcn-svelte's token system makes this nearly automatic

---

## Animation & Motion

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| Page transitions | Fade in | 150ms |
| Modal open/close | Scale + fade | 200ms |
| Toast appear/dismiss | Slide in from right + fade | 300ms |
| Tab switch | Content crossfade | 150ms |
| Photo lightbox open | Scale from thumbnail position | 250ms |
| Save confirmation | Checkmark appear | 200ms |
| Hover on table row | Background color shift | 100ms |
| Sidebar collapse | Width transition | 200ms |

**Rule:** all animations respect `prefers-reduced-motion: reduce` (Tailwind's `motion-reduce:` variant).

---

## Print Styles

- Hide sidebar, header, save bar, navigation
- Show pen detail as a clean single-column layout
- Photos at reasonable size (max 300px width)
- List view prints as a simple table
- Use `@media print` with explicit page breaks between pen records

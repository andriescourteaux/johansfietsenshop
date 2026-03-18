# Shared Hero Banner Design

**Date:** 2026-03-19

## Context

The site already shares a common header partial, but the page-top experience is still split in two:
- the homepage uses the overlay header on top of a full banner image
- single pages use a separate plain intro layout

The new requirement is to fully reuse the homepage-style top banner for single pages as well, but only for the visual shell:
- keep the overlay header and gradient treatment
- keep the banner image area
- do not show opening hours on singles
- do not show page title or intro text inside that banner on singles

The banner image must remain mode-aware by default:
- bike pages default to the bike homepage banner
- drive pages default to the drive homepage banner

Each page must also be able to override the banner per mode when needed.

## Goals

- Reuse the same hero/banner shell on home and single pages.
- Keep the existing homepage content inside the hero only on the homepage.
- Render only image + overlay header on single pages.
- Allow per-page bike and drive banner overrides.
- Keep current mode-aware defaults as fallback.

## Non-Goals

- Do not move opening hours to single pages.
- Do not show hero title or hero intro on single pages.
- Do not redesign the homepage cards or lower page content.
- Do not replace the shared header partial itself.

## Recommended Approach

Create one shared hero/banner partial and make both the homepage and single template use it.

The partial should support two rendering modes:
- `home` mode: banner image, overlay header, opening hours, title, intro
- `banner-only` mode: banner image and overlay header only

Banner source selection should be centralized in the existing mode helper so templates do not duplicate mode-aware fallback logic.

## Design Details

### 1. Shared hero/banner partial

Create a new partial that owns the page-top banner markup now embedded in the homepage.

Responsibilities:
- render the image layer
- render the gradient overlay layer
- rely on the existing shared overlay header above it
- optionally render inner hero content only when requested

This avoids keeping two slightly different hero structures in `index.html` and `single.html`.

### 2. Mode-aware image selection with page overrides

Extend the page-top image logic to support two layers of selection.

Defaults:
- bike mode -> `/images/header_bike.webp`
- drive mode -> `/images/header_drive.webp`

Page overrides:
- `hero_image_bike`
- `hero_image_drive`

Selection rule:
- if the page defines a mode-specific override, use it
- otherwise fall back to the current global bike/drive banner

This works for shared pages like `contact` as well as mode-specific pages.

### 3. Homepage behavior

The homepage uses the shared hero partial in `home` mode.

It keeps:
- the current hero image logic
- opening hours
- title
- intro copy

So the homepage stays visually and functionally the same, but its banner shell becomes reusable.

### 4. Single-page behavior

Single pages use the shared hero partial in `banner-only` mode.

They show:
- the banner image
- the overlay header

They do not show:
- opening hours
- page title in the banner
- intro copy in the banner

The normal page content remains below, in the existing page body layout.

## Files Expected To Change During Implementation

- `layouts/index.html`
- `layouts/_default/single.html`
- `layouts/partials/site-mode.html`
- `layouts/partials/` new shared hero partial
- `assets/css/style.css`
- `tests/verify_site.ps1`
- selected content files only if banner overrides are added immediately

## Verification Strategy

Implementation should be considered complete only after:
- `hugo --destination .test-public`
- `powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html`
- `hugo`
- manual browser checks confirming:
  - home still shows the current hero content
  - single pages show only banner + overlay header at the top
  - single pages do not show opening hours in the hero
  - single pages do not show title/intro in the hero
  - bike/drive mode still switches the default banner correctly
  - a page-level hero override works when front matter is set

## Risks

- If the shared partial still mixes home-only content into the base structure, singles may accidentally inherit opening hours or title markup.
- If banner selection is not centralized, home and singles may drift apart again later.
- CSS spacing may need minor tuning so the new banner-only single-page top does not create an awkward gap before body content.

## Recommendation

Proceed with a shared hero/banner partial and centralized page-level image override logic. That gives true reuse of the homepage header/banner shell while keeping the single-page content area clean and minimal.

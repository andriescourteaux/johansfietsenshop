# Homepage Performance And Opening Hours Design

**Scope**

This design covers four approved changes:

1. Improve homepage scroll performance without changing the visual direction more than necessary.
2. Make the header `Menu` label and icon match the typography and visual weight of `Contact` and `Bikeshop/Driveshop`.
3. Move opening hours out of the homepage hero and render them as a structured table below the homepage cards.
4. Render the same opening hours again in the footer as plain text, sourced from the same homepage content data.

**Approved Constraints**

- Homepage performance is the real concern, specifically stuttery scrolling.
- Homepage and shared-page visuals should stay recognizable; this is not a redesign for a more sober look.
- Homepage card images must use valid `webp` assets only.
- Opening hours remain content-managed from `content/_index.md`.

## Root Cause Summary

The current homepage is heavier than the single pages for two main reasons:

- It renders one full hero plus multiple image-backed homepage cards at once.
- It uses several expensive visual effects during scroll and overlap:
  - large hero media and layered overlays
  - translucent cards with heavy compositing
  - hero-adjacent content overlap that keeps more layers active while scrolling

The header mismatch is separate from performance. The current stylesheet still gives the overlay menu toggle a different font treatment than the neighboring nav links, so `Menu` does not match `Contact` and the mode switch.

The opening-hours block is currently in the hero and rendered as a text list. That makes it visually and structurally tied to the heaviest area of the homepage instead of the content area below it.

## Design Overview

The implementation should keep the existing mode-aware homepage architecture, but make the homepage cheaper to scroll and more consistent:

- keep the shared hero and homepage cards
- keep mode-aware hero image and mode-aware homepage cards
- reduce homepage-only render cost
- normalize the header nav typography
- move opening hours into a dedicated section below the cards
- duplicate the same hours in the footer as plain text from the same source

## Section 1: Homepage Performance

Performance work should target scroll jank, not just transfer size.

### Required changes

- Update homepage card image references in `layouts/partials/site-mode.html` to valid `webp` assets only.
- Mark the hero image in `layouts/partials/shared-hero.html` as the primary image for the page.
- Mark homepage card images in `layouts/index.html` as lower-priority and async-decoded.
- Reduce expensive homepage-only compositing in `assets/css/style.css`:
  - remove or reduce `backdrop-filter` style effects from homepage cards and opening-hours presentation
  - keep overlays, but simplify them where possible to plain layered gradients
  - avoid unnecessary heavy blending on elements that scroll over the hero

### Non-goals

- No structural rewrite of mode switching.
- No conversion to a JavaScript image system.
- No redesign of the cards themselves beyond performance-motivated CSS changes.

## Section 2: Header Consistency

Header navigation should share one type ramp and one visual weight.

### Required changes

- `Menu` must use the same font-size, font-weight, letter-spacing, casing, and baseline alignment as:
  - `Contact`
  - `Bikeshop`
  - `Driveshop`
- The hamburger icon should visually align with the text instead of feeling lighter/smaller.
- The special overlay-only menu-toggle typography override should be removed or folded back into the shared nav rules.

### Expected outcome

The entire right-side header nav should read as one consistent control group in both homepage and single-page contexts.

## Section 3: Opening Hours Placement

Opening hours should no longer live inside the hero.

### Required changes

- Remove the opening-hours panel from the homepage hero content in `layouts/partials/shared-hero.html`.
- Add a dedicated opening-hours section below the homepage cards in `layouts/index.html`.
- Render it as a semantic table rather than a plain unordered list.
- Keep the source data in `content/_index.md`.

### Data approach

The existing `opening_hours` list remains the source of truth. The renderer should parse each line into:

- day label
- value text

This allows the same source list to feed:

- the homepage table
- the footer plain-text version

without introducing a second data structure unless implementation absolutely requires it.

## Section 4: Footer Opening Hours

The footer should show the same opening hours as plain text.

### Required changes

- Add a compact hours block in `layouts/partials/footer.html`.
- Source it from the homepage content data instead of duplicating strings in the template.
- Keep the footer presentation plain-text and compact, not a second table.

## File Impact

Likely implementation targets:

- `content/_index.md`
- `layouts/index.html`
- `layouts/partials/shared-hero.html`
- `layouts/partials/site-mode.html`
- `layouts/partials/header.html`
- `layouts/partials/footer.html`
- `assets/css/style.css`
- `tests/verify_site.ps1`

## Verification Strategy

The final implementation must verify all of the following:

- homepage uses valid `webp` home-card image paths
- homepage hero still renders correctly in bike and drive mode
- homepage cards still switch correctly per mode
- `Menu` shares the same typographic treatment as the other header nav links
- opening hours are absent from the hero
- opening hours render as a table below the homepage cards
- footer contains plain-text opening hours
- `hugo --destination .test-public` succeeds
- `tests/verify_site.ps1` passes against `.test-public`
- `hugo` production build succeeds

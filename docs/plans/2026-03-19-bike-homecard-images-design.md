# Bike Homecard Images Design

**Date:** 2026-03-19

## Context

The bikeshop homepage cards currently all reuse the shared bike hero image via `layouts/partials/site-mode.html`.

The user has now added dedicated bike homecard images in `static/images/home-cards/` and wants only the four bikeshop homepage cards updated to use those files. The driveshop cards should remain unchanged.

## Approved Mapping

Update only the bikeshop panel images in `layouts/partials/site-mode.html`:

- `Merken en verdelers` -> `/images/home-cards/bike-merken.jpg`
- `Accessoires` -> `/images/home-cards/bike-accessoires.webp`
- `Enkele modellen in de kijker` -> `/images/home-cards/bike-modellen.jpg`
- `Leasing fietsen` -> `/images/home-cards/bike-lease.jpg`

## Non-Goals

- Do not change the driveshop card images.
- Do not make homepage cards data-driven in this step.
- Do not change card titles, links, or layout.

## Recommended Approach

Use the existing hardcoded `bikePanels` mapping in `layouts/partials/site-mode.html` and replace only the `image` values for the four bikeshop cards.

This is the smallest correct change and matches the way homepage cards are currently configured.

## Verification

After implementation:
- rebuild the site with `hugo --destination .test-public`
- confirm the homepage output references the four new bike homecard image paths
- optionally run `hugo` as a final build check

# Feedback Redesign Design

## Goal

Apply the feedback from `feedback/feedback-revised.md` to the Hugo site while keeping the implementation small: reuse the existing data-driven collection system, add one split-block layout variant, and update page/content data instead of creating separate one-off templates.

## Clarified Popup Behavior

The promo popup must support both image and text variants.

- If `data/promo-popup.toml` points to an existing image, render the image popup. This keeps `promo.webp` as the priority variant.
- If no image is configured or present, render the text popup using the maintenance message and contact CTA.
- The popup remains session-dismissed with `sessionStorage`, using the existing popup script.

## Content Changes

Home page becomes mode-specific:

- Bike title: `Start een nieuw avontuur`
- Bike subtitle: `Herstelling van alle merken en verkoop van nieuwe fietsen`
- Drive title: `Geniet van een perfect verzorgde tuin.`
- Drive subtitle: `Herstelling van alle merken en verkoop van nieuwe en tuinmachines`
- Opening hours move from the homepage body to the contact page.

Navigation changes:

- Bike: rename `Merken en verdelers` to `Onze merken`; remove `Enkele modellen in de kijker` from menu and homepage cards.
- Drive: rename `Merken en verdelers` to `Onze merken`; remove `Modellen in de kijker` from menu and homepage cards; rename `Winteronderhoud van tuinmachines` link text to `Winteronderhoud`.
- Keep removed page URLs buildable for now to avoid breaking old links.

Footer changes:

- Use `info@johansfietsenshop.be`.
- Use `0472 93 03 56`.
- Make the address link to Google Maps.
- Add Instagram link.
- Add `BE 0898284633` with the requested Belgian flag marker.
- Add `Zondag en feestdagen gesloten` under opening hours.

## Layout Changes

Add a shared split-block pattern:

- Two touching columns on desktop.
- Stack on mobile.
- Alternates image/text per row.
- Supports text, optional button, optional image link, and hover image behavior.

Use this same pattern for:

- Bike home promo rows.
- Drive home promo rows.
- Bike brand page.
- Drive brand page.
- Leasing page.
- Accessories page.
- About page intro row.

This avoids new custom templates per page.

## Data Model

Extend existing collection TOML items with fields already used or simple additions:

- `title`
- `alt`
- `image`
- `intro`
- `url`
- `button_label`
- `weight`

Use `collection_variant = "split-blocks"` for alternating rows.

Add one small homepage data file instead of hard-coding long blocks in the template:

- `data/home.toml`

Add one small about data file only if the page content becomes too awkward in Markdown. Prefer Markdown front matter plus body first.

## Assets

Copy feedback assets into public static folders:

- `feedback/headshot.webp` -> `static/images/about/headshot.webp`
- `feedback/basil.jpg` -> `static/images/collecties/bikeshop/accessoires/basil.jpg`
- `feedback/vdb.jpg` -> `static/images/collecties/bikeshop/accessoires/vdb.jpg`
- `feedback/axa.webp` -> `static/images/collecties/bikeshop/accessoires/axa.webp`
- `feedback/lvw.jpg` -> `static/images/collecties/bikeshop/accessoires/lvw.jpg`
- `feedback/thule.jpg` -> `static/images/collecties/bikeshop/accessoires/thule.jpg`
- `feedback/welease.svg` -> `static/images/collecties/bikeshop/leasing-fietsen/welease.svg`
- `feedback/vegemac_tb.webp` -> `static/images/collecties/driveshop/merken-en-verdelers/vegemac_tb.webp`
- `feedback/iseki_tb.jpg` -> `static/images/collecties/driveshop/merken-en-verdelers/iseki_tb.jpg`
- `feedback/castelgarden_tb.webp` -> `static/images/collecties/driveshop/merken-en-verdelers/castelgarden_tb.webp`
- `feedback/stiga_tb.png` -> `static/images/collecties/driveshop/merken-en-verdelers/stiga_tb.png`
- `feedback/makita_tb.jpg` -> `static/images/collecties/driveshop/merken-en-verdelers/makita_tb.jpg`
- `feedback/advies.webp` -> `static/images/home/advies.webp`

Use existing images where feedback does not provide new ones:

- `static/images/home-cards/bike-modellen.webp` for the bike test-ride row.
- `static/images/home-cards/drive-maintenance.webp` for `tuinmachine.webp` unless a specific `tuinmachine.webp` is later provided.

Payment logos are referenced but not supplied. Add expected paths as placeholders only:

- `/images/payment/cash.svg`
- `/images/payment/bancontact.svg`
- `/images/payment/payconiq.svg`

## Page-Specific Behavior

Bike brand page:

- Title `Onze merken`.
- No intro text block.
- No filters.
- Split-block rows for Swyff, Oxford, Thompson, Zannata, L'Avenir, Gazelle, Descheemaeker, Flanders, BFK, RAVR.
- Keep images clickable to external brand URLs.

Leasing page:

- Title `Leasing`.
- No intro text block.
- Split-block rows with `Meer informatie` buttons.
- Add Welease.
- Update Velobility URL to `https://www.cyclobility.be/nl`.

Accessories page:

- No intro text block.
- Split-block rows for Basil, VDB Parts, Axa, Louis Verwimp, Thule.

About page:

- New `Over ons` page.
- Headshot left, quote right.
- Vision section centered below.
- Three centered value blocks.
- Include the same highlights section used on the bike home page.

Contact page:

- Remove form and duplicated contact information.
- Add intro text.
- Add two top info blocks.
- Add phone and email icon buttons.
- Add payment methods section.
- Keep map.
- Add two lower service blocks.
- Show opening hours here.

Winter maintenance page:

- Rename title to `Maak je tuinmachines winterklaar (inclusief haal- en brengservice!)`.
- Replace body text with provided winter maintenance copy.
- Add `Neem contact op` button.

## Validation

Update `tests/verify_site.ps1` to cover:

- Popup image priority and text fallback hooks.
- Drive pages render `data-site-mode="drive"`.
- Homepage no longer contains the opening-hours section.
- Contact page contains opening hours and no disabled contact form.
- Footer has new contact data.
- New split-block variant appears on brand, leasing, accessories, and home pages.
- Removed menu/card links are absent.
- New about page builds.
- Winter page title and contact CTA render.

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```


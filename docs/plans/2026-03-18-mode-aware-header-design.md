# Mode-Aware Header and Homepage Design

## Context

The current Hugo site already has:

- a shared header partial
- a shared contact page
- a full-screen homepage hero
- a single `merken en verdelers` page
- one shared stylesheet loaded from Hugo assets

The repository currently also contains the new image assets needed for this change under `static/images/`, including `logo.png`, `logo-drive.png`, `header_bike.jpg`, and `header_drive.jpg`.

## Goal

Add a persistent two-mode navigation model to the site:

- `bike` mode
- `drive` mode

The mode must affect:

- the header logo image
- the homepage hero image
- the visible shop switch link in the header
- the destination of the `merken en verdelers` header link
- the links generated on shared pages such as Home and Contact

## Approved Decisions

- `logo.png` is used only in bike mode.
- `logo-drive.png` is used only in drive mode.
- The logo remains the clickable home link in both modes.
- The current homepage hero image is bike-only.
- `header_drive.jpg` is used as the drive-mode homepage hero image.
- The site uses URL-driven mode as the main source of truth.
- In bike mode, the header shows only the `Driveshop` switch link.
- In drive mode, the header shows only the `Bikeshop` switch link.
- Home and Contact are shared pages available in both modes.
- `Merken en verdelers` has two separate versions, one for bike mode and one for drive mode.
- The site should remember the active mode when the visitor returns to Home or Contact.

## Mode Model

### Canonical mode sources

The active mode is derived in this order:

1. Page route for dedicated shop pages
   - `/bikeshop/` => `bike`
   - `/driveshop/` => `drive`
2. Page route for dedicated `merken en verdelers` variants
   - `/bikeshop/merken-en-verdelers/` => `bike`
   - `/driveshop/merken-en-verdelers/` => `drive`
3. URL query parameter on shared pages
   - `?mode=bike`
   - `?mode=drive`
4. Small client-side fallback using stored last mode when no explicit mode is present on a shared page

### Persistence behavior

The shared pages do not define the mode by themselves. They inherit it through URL parameters and preserve it in generated navigation links. A tiny client-side fallback may apply the remembered mode only when a shared page is loaded without an explicit mode in the URL.

## Information Architecture

The design keeps the current shared pages and adds two mode-specific `merken en verdelers` pages.

### Shared pages

- `/`
- `/contact/`

### Mode-specific pages

- `/bikeshop/`
- `/driveshop/`
- `/bikeshop/merken-en-verdelers/`
- `/driveshop/merken-en-verdelers/`

This route structure keeps the mode visible in dedicated pages and makes the `merken en verdelers` sibling relationship explicit.

## Header Behavior

The header becomes mode-aware.

### Logo

- bike mode => `static/images/logo.png`
- drive mode => `static/images/logo-drive.png`
- both remain wrapped in the same home link

### Navigation

The header should always include:

- Home
- Contact
- Merken en verdelers
- exactly one mode-switch link

Mode-switch rules:

- bike mode => show only `Driveshop`
- drive mode => show only `Bikeshop`

The `Merken en verdelers` link resolves dynamically:

- bike mode => `/bikeshop/merken-en-verdelers/`
- drive mode => `/driveshop/merken-en-verdelers/`

For Home and Contact, the active mode is preserved through the URL query string.

## Homepage Behavior

The homepage keeps the existing full-screen hero structure, but the rendered hero image depends on mode.

- bike mode => current bike hero image
- drive mode => `header_drive.jpg`

The overlay, copy, and layout stay visually consistent so the only meaningful variation is brand/mode identity.

## Content Model

The existing shared `merken en verdelers` page is replaced by two separate content entries:

- bike version
- drive version

They can share the same layout structure but should contain mode-appropriate placeholder text so the distinction is visible during testing.

Home and Contact remain single shared pages.

## Technical Approach

### Templating

Add a small Hugo helper layer, likely a partial, to compute:

- current mode
- correct logo asset path
- correct hero asset path
- correct switch-link destination
- correct `merken en verdelers` destination
- shared-page links with mode query parameters

### Client-side fallback

Use a small inline or bundled script on shared pages to:

- remember the latest explicit mode selection
- restore that mode only when the page URL does not already specify one

This keeps URL behavior canonical while still satisfying the requirement that shared pages remember the last active mode.

### Styling

Update header styling so logo images replace the current text brand cleanly:

- stable logo height
- mode-independent header alignment
- no layout jump between bike and drive logos

## Error Handling and Edge Cases

- Invalid mode query values should fall back to `bike`.
- Shared pages without query mode and without stored mode should default to `bike`.
- Dedicated shop and mode-specific `merken en verdelers` pages override any conflicting query parameter.
- If one logo or hero asset is missing, the build should fail visibly in verification before completion.

## Verification Targets

Implementation should verify:

- Hugo build still succeeds
- header renders `logo.png` in bike mode
- header renders `logo-drive.png` in drive mode
- bike mode header shows only `Driveshop`
- drive mode header shows only `Bikeshop`
- homepage uses bike hero in bike mode
- homepage uses `header_drive.jpg` in drive mode
- `merken en verdelers` header link targets the correct mode-specific page
- Home and Contact preserve mode in their generated links
- shared pages default safely to bike mode when no explicit mode is provided

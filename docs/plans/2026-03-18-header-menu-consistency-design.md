# Header Menu Consistency Design

**Date:** 2026-03-18

## Context

The current site already uses one shared header partial, but three issues remain in practice:

1. The hamburger menu shows both bike and drive links instead of only the links for the active mode.
2. The hamburger menu is visually anchored too far from the toggle button and can open toward the wrong side of the screen.
3. Single pages still render the same header component with a different typographic and spacing context than the homepage, causing a visible font/style mismatch and a small vertical jump.

The user explicitly does not want the homepage hero layout copied to single pages. Only the site navigation and logo treatment should be identical and stable across home and single pages.

## Goals

- Show only bike menu entries in bike mode.
- Show only drive menu entries in drive mode.
- Position the dropdown directly under the hamburger toggle on desktop, with predictable mobile fallback.
- Use one consistent navigation typography and vertical rhythm for home and single pages.
- Remove the small up/down jump when moving between homepage and single pages.

## Non-Goals

- Do not redesign the homepage hero.
- Do not turn single pages into homepage-style hero layouts.
- Do not change the overall information architecture or menu contents.

## Recommended Approach

Use the existing shared header component as the single source of truth and normalize the surrounding CSS and mode-sync behavior.

This means:
- keep one shared header partial
- keep mode-aware menu data in the existing site-mode helper
- fix the filtering bug in CSS and JS together
- move dropdown positioning into the local navigation shell instead of the wider header container
- centralize nav typography outside the overlay-only selector

This solves all three symptoms without introducing a second header implementation.

## Design Details

### 1. Mode-aware menu visibility

The current menu already renders separate bike and drive lists with `data-mode-nav` and the `hidden` attribute. The likely failure is that CSS forces those lists back to `display: grid`, overriding `hidden`.

The fix should make visibility robust at three layers:
- markup keeps distinct bike and drive lists
- CSS explicitly respects `[hidden]` on those lists
- JavaScript continues to toggle the correct list, and may also update `aria-hidden` for clarity

Result:
- bike mode shows only the bike list
- drive mode shows only the drive list
- switching mode updates the active list consistently on shared pages

### 2. Dropdown anchoring

The dropdown currently lives in a wider container context than the toggle button. This makes the absolute positioning feel detached from the button.

The fix should:
- wrap the toggle and dropdown in one small local positioning shell inside the nav
- set that shell as the absolute-positioning anchor
- align the dropdown to the right edge of the toggle on desktop
- keep a constrained full-width/mobile behavior only under the small-screen breakpoint

Result:
- the dropdown opens under the hamburger button instead of floating across the page

### 3. Shared nav typography and spacing

The current mismatch comes from overlay-only rules that change font sizing, family treatment, and spacing for the homepage header, while single pages use the non-overlay baseline.

The fix should:
- move shared nav typography to the base selectors for brand, nav links, switch link, toggle, and dropdown links
- limit overlay-specific styling to color, opacity, and hover contrast only
- normalize header inner padding so home and single pages do not shift vertically
- replace unstable viewport-height font sizing with a stable rem-based value

Result:
- home and singles use the same navigation font styling
- header height remains visually stable
- the logo and nav do not jump slightly between page types

## Files Expected To Change During Implementation

- `layouts/partials/header.html`
- `layouts/partials/mode-script.html`
- `assets/css/style.css`
- `tests/verify_site.ps1`

## Verification Strategy

Implementation should be considered complete only after:
- `hugo --destination .test-public`
- `powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html`
- `hugo`
- manual browser check of:
  - bike menu shows only bike links
  - drive menu shows only drive links
  - menu opens directly below the toggle
  - home and single-page nav typography match
  - no visible vertical jump between home and single pages

## Risks

- A generic `.site-nav__menu-list { display: grid; }` rule can keep overriding `hidden` if the fix is not explicit enough.
- Fixing the dropdown anchor in the wrong container can regress mobile layout.
- Typography changes must be applied to both plain links and the menu toggle, otherwise the mismatch will persist in a subtler form.

## Recommendation

Proceed with a focused header consistency fix rather than a page layout redesign. The correct scope is the shared header component, its mode synchronization, and its CSS foundation.

# Light Motion And Theme Polish Design

## Goal
Add subtle, performance-safe motion and stronger bike/drive theming without making the site feel slow. The site should feel a little more alive, but still remain sober and smooth.

## Chosen Approach
Use a CSS-first approach with small JS hooks in the existing mode and menu script. All motion stays on cheap properties like `transform`, `opacity`, `background-color`, `color`, and `box-shadow`. No animation on layout properties, no animated blur, and no animation library.

This keeps the implementation small and aligned with the current Hugo structure:
- header and mode logic stay centralized
- the shared hero remains the single source for banner behavior on home and singles
- footer theming stays mode-aware through the existing bike/drive state

## Motion Principles
- Keep all transitions short, roughly `140ms` to `220ms`
- Prefer `transform` and `opacity`
- Avoid `height`, `top`, `left`, `filter`, `backdrop-filter`, and large paint-heavy effects
- Respect `prefers-reduced-motion`
- Make mode changes feel soft, not theatrical
- Keep hover states visible but restrained

## Header And Mode Toggle
The current text switch becomes a true toggle-pill while keeping visible text. The active label should be:
- `Johan's Fietsenshop` in bike mode
- `Johan's Driveshop` in drive mode

Behavior:
- bike mode uses a yellow active state
- drive mode uses a red active state
- the toggle thumb slides between states
- the text remains readable and explicit

The existing mode storage and switching logic remain the source of truth. Only the presentation and micro-motion change.

## Header Menu Motion
The hamburger menu should animate in with a light downward slide and fade instead of simply appearing. It should remain anchored to the existing button and still use the current mode-aware content.

Behavior:
- open: slight `translateY` down-to-rest plus fade-in
- close: slight reverse move plus fade-out
- closed state still uses `hidden` so accessibility and layout remain clean

## Theme Synchronization
Mode color becomes more explicit across the interface:
- bike mode: yellow accent, yellow footer
- drive mode: red accent, red footer

This should be done with CSS variables keyed from the existing mode state on `body` or root layout elements. The footer background should transition smoothly when the mode changes so the site feels coherent instead of abruptly restyled.

## Hover States
Subtle hover motion should be added where it adds value without noise.

Homepage cards:
- slight image scale
- slight overlay shift or shadow deepen
- no large lift or dramatic zoom

Photo and image-driven cards elsewhere:
- similarly small hover response
- avoid adding motion to static brand-logo grids that are meant to stay sober

## Mode Transition Feel
When switching between bike and drive mode, the change should not feel like a hard swap.

Apply a small shared transition to:
- logo source change
- toggle-pill state
- footer theme color
- homepage card set fade/slide
- hero image swap

This should be done with small class hooks in the existing mode script, not with a page transition framework.

## Hero Parallax
The shared hero partial is already used by home and single pages, so it is the right place for the banner motion hook.

Behavior:
- apply a very small parallax offset to the hero image on scroll
- use `requestAnimationFrame`
- only move the image by a small amount, roughly `18px` to `28px` max
- disable the effect under `prefers-reduced-motion`
- keep the overlay and content stable while only the image shifts slightly behind them

## Accessibility And Performance Guards
- Add a `prefers-reduced-motion` CSS branch and script guard
- Do not animate on first paint in a way that blocks interaction
- Avoid adding more than one scroll animation loop
- Keep mode transitions and hover effects independent of layout recalculation

## Files Most Likely To Change
- `layouts/partials/header.html`
- `layouts/partials/mode-script.html`
- `layouts/partials/shared-hero.html`
- `layouts/index.html`
- `assets/css/style.css`
- `tests/verify_site.ps1`

## Verification Strategy
Generated-site checks should confirm the new structural hooks exist:
- toggle-pill markup/classes in header
- mode-aware footer theme markers
- menu animation classes or state hooks
- shared hero parallax hook
- `prefers-reduced-motion` safeguards

Manual browser verification remains necessary for feel and smoothness:
- toggle looks right in both modes
- footer color follows mode
- menu slides down cleanly
- hover states stay subtle
- parallax is noticeable but restrained
- no new stutter appears on scroll
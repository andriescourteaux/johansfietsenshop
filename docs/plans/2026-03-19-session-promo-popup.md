# Session Promo Popup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a lightweight, sitewide promotion popup that shows once per browser or tab session, can be disabled from a data file, and stays fully standalone from the rest of the website logic.

**Architecture:** Keep the feature global and self-contained. A small data file controls activation and image source, a shared partial renders the popup into the base layout, a dedicated script partial manages session-only dismissal with `sessionStorage`, and the existing stylesheet provides the modal visuals and reduced-motion-safe transitions.

**Tech Stack:** Hugo templates and data files, local CSS, light client-side JavaScript, PowerShell verifier, git workflow.

---

### Task 1: Lock the verifier onto the popup behavior first

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Add failing checks for the popup markup and toggles**

Update the verifier so it checks:
- popup root markup exists when the feature is enabled
- popup root markup does not exist when the feature is disabled
- popup image source comes from the configured promo image
- close-button hook exists
- backdrop hook exists
- session script hook exists

The verifier should be able to read `data/promo-popup.toml` and assert that the generated output matches the enabled or disabled state.

**Step 2: Run the verifier to confirm it fails first**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: FAIL because the popup markup and hooks do not exist yet.

**Step 3: Commit the failing-test change**

```powershell
git add tests/verify_site.ps1
git commit -m "test: cover session promo popup"
```

### Task 2: Add the data-driven popup markup to the global layout

**Files:**
- Create: `data/promo-popup.toml`
- Create: `layouts/partials/promo-popup.html`
- Modify: `layouts/_default/baseof.html`

**Step 1: Create the popup data file**

Create `data/promo-popup.toml` with this minimal structure:

```toml
enabled = true
image = "/images/promo/actie.webp"
alt = "Promotie"
```

This file is the only place needed to disable the feature later.

**Step 2: Create the popup partial**

Create `layouts/partials/promo-popup.html` so it:
- reads `.Site.Data.promo_popup`
- returns nothing when `enabled` is false
- renders the popup container only when enabled is true
- includes:
  - a root element such as `data-promo-popup="root"`
  - a backdrop such as `data-promo-popup="backdrop"`
  - a card wrapper
  - the configured image
  - a close button such as `data-promo-popup="close"`

A suitable markup direction is:

```gohtml
{{ with .Site.Data.promo_popup }}
{{ if .enabled }}
<div class="promo-popup" data-promo-popup="root" hidden>
    <button class="promo-popup__backdrop" type="button" aria-label="Sluit promotie" data-promo-popup="backdrop"></button>
    <div class="promo-popup__dialog" role="dialog" aria-modal="true" aria-label="Promotie">
        <button class="promo-popup__close" type="button" aria-label="Sluit promotie" data-promo-popup="close">×</button>
        <img class="promo-popup__image" src="{{ .image }}" alt="{{ .alt }}" loading="eager" decoding="async">
    </div>
</div>
{{ end }}
{{ end }}
```

**Step 3: Load the partial globally**

In `layouts/_default/baseof.html`, render the popup partial near the end of `<body>`, before the scripts. Example placement:

```gohtml
    {{ partial "footer.html" . }}
    {{ partial "promo-popup.html" . }}
    {{ partial "mode-script.html" . }}
```

**Step 4: Run the verifier and build**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: popup markup assertions pass, while script or styling checks may still fail.

**Step 5: Commit**

```powershell
git add data/promo-popup.toml layouts/partials/promo-popup.html layouts/_default/baseof.html
git commit -m "feat: add global promo popup markup"
```

### Task 3: Implement session-only dismissal and lightweight popup styling

**Files:**
- Create: `layouts/partials/promo-popup-script.html`
- Modify: `layouts/_default/baseof.html`
- Modify: `assets/css/style.css`

**Step 1: Add the popup script partial**

Create `layouts/partials/promo-popup-script.html` with a small self-invoking script that:
- selects the popup root and its close/backdrop controls
- exits early if the popup is not rendered
- uses a session key such as `promo-popup-dismissed`
- unhides the popup only when the session key is absent
- closes the popup on close-button click
- closes the popup on backdrop click
- writes the dismiss flag to `sessionStorage`

Example implementation direction:

```html
<script id="promo-popup-script">
(() => {
  const root = document.querySelector('[data-promo-popup="root"]');
  if (!root) return;

  const closeButton = root.querySelector('[data-promo-popup="close"]');
  const backdrop = root.querySelector('[data-promo-popup="backdrop"]');
  const storageKey = 'promo-popup-dismissed';
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const closePopup = () => {
    root.dataset.state = 'closing';
    window.sessionStorage.setItem(storageKey, '1');

    if (reducedMotion) {
      root.hidden = true;
      return;
    }

    window.setTimeout(() => {
      root.hidden = true;
      root.dataset.state = 'closed';
    }, 180);
  };

  if (window.sessionStorage.getItem(storageKey) === '1') {
    root.hidden = true;
    root.dataset.state = 'closed';
    return;
  }

  root.hidden = false;
  root.dataset.state = 'open';

  closeButton?.addEventListener('click', closePopup);
  backdrop?.addEventListener('click', closePopup);
})();
</script>
```

**Step 2: Load the script globally**

In `layouts/_default/baseof.html`, load the script after the popup partial and before the existing mode script:

```gohtml
    {{ partial "promo-popup.html" . }}
    {{ partial "promo-popup-script.html" . }}
    {{ partial "mode-script.html" . }}
```

**Step 3: Add lightweight popup styles**

In `assets/css/style.css`, add the popup styles with:
- fixed positioning over the viewport
- a subtle backdrop
- centered dialog with moderate width
- responsive image sizing
- clear close button
- light opacity/translate transition only
- `prefers-reduced-motion` guard

A suitable direction is:

```css
.promo-popup {
    position: fixed;
    inset: 0;
    z-index: 80;
    display: grid;
    place-items: center;
    padding: 1.5rem;
}

.promo-popup__dialog {
    position: relative;
    width: min(34rem, 100%);
    border-radius: 0.9rem;
    overflow: hidden;
    background: #fff;
    box-shadow: 0 1.4rem 3rem rgba(16, 16, 16, 0.22);
    transform: translateY(0.6rem);
    opacity: 0;
    transition: transform 180ms ease, opacity 180ms ease;
}

.promo-popup[data-state="open"] .promo-popup__dialog {
    transform: translateY(0);
    opacity: 1;
}
```

Avoid expensive filters like `backdrop-filter`.

**Step 4: Run build plus verifier**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: build succeeds and popup verifier checks pass.

**Step 5: Commit**

```powershell
git add layouts/partials/promo-popup-script.html layouts/_default/baseof.html assets/css/style.css
git commit -m "feat: add session-based promo popup behavior"
```

### Task 4: Validate the disabled state and session flow

**Files:**
- Modify: `data/promo-popup.toml`
- Modify: `tests/verify_site.ps1`

**Step 1: Verify the enabled state manually**

With `enabled = true`, run the site locally:

```powershell
hugo server
```

Manual checks:
- popup appears on first page load
- popup closes with the close button
- popup closes when clicking the backdrop
- popup does not return after navigation within the same tab

**Step 2: Verify the disabled state**

Temporarily change the data file to:

```toml
enabled = false
image = "/images/promo/actie.webp"
alt = "Promotie"
```

Then run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: generated output contains no popup root markup and the verifier still passes.

Restore `enabled = true` if the promo should remain active by default.

**Step 3: Commit the final verified state**

If the promo should remain available by default:

```powershell
git add data/promo-popup.toml tests/verify_site.ps1
git commit -m "test: verify promo popup enabled and disabled states"
```

If the promo should ship disabled by default, use that final data file content instead before committing.

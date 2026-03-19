# Light Motion And Theme Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add subtle, performant motion polish, a real bike/drive toggle-pill, synchronized footer theming, and shared-hero parallax across home and single pages.

**Architecture:** Keep the current Hugo mode-aware structure and build the motion layer with CSS-first transitions plus small JS hooks in the existing header and mode script. Shared hero behavior stays centralized in `shared-hero.html`, while theme changes are driven by mode-aware CSS variables and minimal class toggles.

**Tech Stack:** Hugo templates, local static assets, vanilla JS, CSS transitions, PowerShell site verification.

---

### Task 1: Extend The Verifier For Motion And Theme Hooks

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Write the failing test**

Add assertions for:
- header contains a dedicated toggle-pill hook instead of only the old plain switch text
- CSS contains mode-aware footer theme markers for bike and drive
- menu animation hooks or classes exist
- shared hero markup includes a parallax hook
- CSS includes a `prefers-reduced-motion` branch

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- `hugo --destination .test-public` passes
- verifier fails on the new motion/theme expectations

**Step 3: Commit**

```powershell
git add tests/verify_site.ps1
git commit -m "test: add motion and theme polish checks"
```

### Task 2: Replace The Plain Mode Link With A Toggle Pill

**Files:**
- Modify: `layouts/partials/header.html`
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the red verifier from Task 1 as the failing test for missing toggle-pill hooks.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier reports missing toggle-pill structure/theme hooks

**Step 3: Write minimal implementation**

In `layouts/partials/header.html`, replace the current plain shop switch presentation with a dedicated pill control that still links through the existing mode system and renders:

```html
<a class="site-nav__mode-toggle" ...>
  <span class="site-nav__mode-track">
    <span class="site-nav__mode-thumb"></span>
  </span>
  <span class="site-nav__mode-text">Johan's Fietsenshop</span>
</a>
```

In `layouts/partials/mode-script.html`, update the existing mode application logic so it also:
- swaps the visible text between `Johan's Fietsenshop` and `Johan's Driveshop`
- moves the toggle state between bike and drive
- keeps the existing href/data-attribute behavior

In `assets/css/style.css`, add the pill styles using shared nav typography and mode-aware colors.

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- toggle-pill-related failures disappear
- later motion checks may still fail

**Step 5: Commit**

```powershell
git add layouts/partials/header.html layouts/partials/mode-script.html assets/css/style.css
git commit -m "feat: add mode toggle pill"
```

### Task 3: Add Menu Slide Motion And Footer Theme Sync

**Files:**
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`
- Modify: `layouts/partials/footer.html`

**Step 1: Write the failing test**

Use the remaining verifier failures for menu motion/theme hooks as the failing test.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier still reports missing menu animation or footer theme markers

**Step 3: Write minimal implementation**

In `layouts/partials/mode-script.html`:
- add enter/exit classes for the hamburger menu
- preserve `hidden` as the real closed state
- update a mode-aware theme attribute or class used by the footer

In `assets/css/style.css`:
- animate menu open/close with `opacity` and `transform`
- define bike/drive theme variables
- apply yellow footer in bike mode and red footer in drive mode
- animate footer color change with `background-color`

In `layouts/partials/footer.html`, keep the existing structure and let the theme come from CSS variables/classes only.

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- menu/theme failures disappear
- remaining hover/parallax checks may still fail

**Step 5: Commit**

```powershell
git add layouts/partials/mode-script.html layouts/partials/footer.html assets/css/style.css
git commit -m "feat: animate menu and sync footer theme"
```

### Task 4: Add Subtle Hover Motion And Mode Transition Hooks

**Files:**
- Modify: `layouts/index.html`
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the remaining verifier failures for motion hooks as the failing test.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier still reports missing hover or mode-transition hooks

**Step 3: Write minimal implementation**

In `assets/css/style.css`, add restrained hover motion for homepage cards:

```css
.overview-card:hover .overview-card__image {
  transform: scale(1.03);
}

.overview-card:hover {
  box-shadow: 0 1rem 2.1rem rgba(16, 16, 16, 0.18);
}
```

In `layouts/index.html`, add any minimal wrapper classes needed for mode transition fades.

In `layouts/partials/mode-script.html`, add a short mode-change class cycle so the home card panel, logo, and hero swap can fade/slide lightly without a full page transition.

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- hover and mode-transition hook failures disappear
- parallax or reduced-motion checks may still fail

**Step 5: Commit**

```powershell
git add layouts/index.html layouts/partials/mode-script.html assets/css/style.css
git commit -m "feat: add subtle motion polish"
```

### Task 5: Add Shared-Hero Parallax With Reduced-Motion Guard

**Files:**
- Modify: `layouts/partials/shared-hero.html`
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the remaining verifier failures for parallax/reduced-motion support as the failing test.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier still reports missing parallax or reduced-motion hooks

**Step 3: Write minimal implementation**

In `layouts/partials/shared-hero.html`, add a clear parallax target hook on the hero image.

In `layouts/partials/mode-script.html`, implement one `requestAnimationFrame`-driven scroll updater that:
- only targets the shared hero image
- only applies a small offset
- no-ops when `prefers-reduced-motion` is active
- avoids work when no hero is present

In `assets/css/style.css`, add:
- a transition-safe transform target on the hero image
- a `prefers-reduced-motion: reduce` block disabling transitions/parallax motion

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier passes the new motion/theme checks

**Step 5: Commit**

```powershell
git add layouts/partials/shared-hero.html layouts/partials/mode-script.html assets/css/style.css
git commit -m "feat: add shared hero parallax"
```

### Task 6: Final Verification

**Files:**
- Verify only

**Step 1: Run full generated-site verification**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- both commands succeed
- `All site verification checks passed.`

**Step 2: Run production build verification**

```powershell
hugo
```

Expected:
- build succeeds with exit code `0`

**Step 3: Run manual browser verification**

Check in the browser:
- bike mode shows yellow toggle + yellow footer
- drive mode shows red toggle + red footer
- toggle text changes between `Johan's Fietsenshop` and `Johan's Driveshop`
- menu slides down instead of popping in
- homecards get subtle hover motion
- mode switching feels softer but still fast
- hero parallax works on home and single pages
- `prefers-reduced-motion` disables the extra motion
- no new stutter appears during scroll

**Step 4: Commit**

```powershell
git add tests/verify_site.ps1 layouts/partials/header.html layouts/partials/mode-script.html layouts/partials/shared-hero.html layouts/index.html layouts/partials/footer.html assets/css/style.css
git commit -m "feat: add light motion and theme polish"
```
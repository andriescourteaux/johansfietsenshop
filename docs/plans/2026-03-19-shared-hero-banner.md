# Shared Hero Banner Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reuse the homepage-style overlay header and banner shell on single pages while keeping single-page heroes image-only and mode-aware with optional per-page banner overrides.

**Architecture:** Extract the current homepage hero shell into one shared partial, then call it from both the homepage and single-page templates with different rendering flags. Centralize bike/drive banner fallback and per-page override resolution in the existing site-mode helper so templates stay thin.

**Tech Stack:** Hugo templates, Hugo partials, front matter, site CSS, PowerShell verification script.

---

### Task 1: Extend verification for shared hero reuse

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Write the failing verification changes**

Update the verifier so it checks that:
- single pages now contain the shared hero/banner markers
- single pages still include the overlay-header-compatible hero image wrapper
- single pages do not contain opening-hours markup inside the banner
- single pages do not contain homepage hero text markers inside the banner
- CSS still includes the required hero-image markers

**Step 2: Run verification to confirm it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- Hugo build succeeds
- verifier fails because single pages do not yet render the shared hero/banner shell

**Step 3: Commit the verification change**

```powershell
git add tests/verify_site.ps1
git commit -m "test: verify shared hero banner reuse"
```

### Task 2: Create the shared hero partial

**Files:**
- Create: `layouts/partials/shared-hero.html`
- Modify: `layouts/index.html`

**Step 1: Extract the homepage hero shell into a shared partial**

The new partial should support at least:
- image layer
- overlay layer
- optional hero-content rendering flag
- optional opening-hours rendering flag
- optional title and intro rendering flag

Keep the homepage as the first consumer.

**Step 2: Replace the inline homepage hero markup**

Update `layouts/index.html` so it calls the new shared partial instead of owning the hero markup inline.

**Step 3: Rebuild the site**

Run:
```powershell
hugo --destination .test-public
```

Expected:
- build succeeds
- homepage output still contains the same hero markers and content

**Step 4: Commit the extraction**

```powershell
git add layouts/partials/shared-hero.html layouts/index.html
git commit -m "refactor: extract shared hero banner partial"
```

### Task 3: Add mode-aware page-level banner overrides

**Files:**
- Modify: `layouts/partials/site-mode.html`

**Step 1: Add page-level banner override resolution**

Extend the mode helper to calculate:
- default bike hero image
- default drive hero image
- page-specific `hero_image_bike`
- page-specific `hero_image_drive`
- final resolved hero image per active mode

Keep homepage defaults unchanged when no page override exists.

**Step 2: Verify the helper compiles cleanly**

Run:
```powershell
hugo --destination .test-public
```

Expected:
- build succeeds
- homepage still resolves the same default hero assets

**Step 3: Commit the override logic**

```powershell
git add layouts/partials/site-mode.html
git commit -m "feat: add page-level hero banner overrides"
```

### Task 4: Reuse the shared hero on single pages

**Files:**
- Modify: `layouts/_default/single.html`
- Modify: `assets/css/style.css`

**Step 1: Render the shared hero in banner-only mode on singles**

Update `single.html` so it renders the new shared hero partial before the page body.

In single-page mode, the shared hero must show:
- image
- overlay layer

It must not show:
- opening hours
- page title inside hero
- intro text inside hero

**Step 2: Adjust spacing if needed**

Update CSS only as much as needed so:
- the new banner-only top section sits cleanly above single-page content
- no extra awkward gap appears
- the shared overlay-header behavior still looks correct

**Step 3: Run verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier passes the new shared-hero checks

**Step 4: Commit the single-page reuse**

```powershell
git add layouts/_default/single.html assets/css/style.css
git commit -m "feat: reuse hero banner on single pages"
```

### Task 5: Optional page-level banner example and final verification

**Files:**
- Optionally modify: selected `content/*.md` files
- Review: `layouts/partials/shared-hero.html`
- Review: `layouts/partials/site-mode.html`
- Review: `layouts/index.html`
- Review: `layouts/_default/single.html`
- Review: `tests/verify_site.ps1`

**Step 1: Optionally add one real banner override example**

If desired, add `hero_image_bike` or `hero_image_drive` to one content file as a concrete example of the new capability.

**Step 2: Run full verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
hugo
```

Expected:
- all commands exit 0
- verifier prints `All site verification checks passed.`

**Step 3: Manually inspect in browser**

Run:
```powershell
hugo server
```

Verify manually:
- homepage still shows image + overlay header + opening hours + title + intro
- contact and other single pages show only image + overlay header at the top
- single pages do not show opening hours in the banner
- single pages do not show title/intro in the banner
- bike and drive default banners still switch correctly
- any example page override is respected

**Step 4: Review final diff and commit any final adjustments**

Run:
```powershell
git diff --stat HEAD~4 HEAD
git status --short
```

If needed:
```powershell
git add layouts/partials/shared-hero.html layouts/partials/site-mode.html layouts/index.html layouts/_default/single.html assets/css/style.css tests/verify_site.ps1 content/*.md
git commit -m "chore: finalize shared hero banner reuse"
```

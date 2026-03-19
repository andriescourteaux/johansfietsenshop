# Homepage Performance And Opening Hours Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve homepage scroll performance, unify header nav typography, move opening hours into a table below the homepage cards, and repeat the same hours as plain text in the footer.

**Architecture:** Keep the existing Hugo mode-aware homepage structure, but reduce homepage-only scroll cost by using valid `webp` card images, simpler compositing, and correct image loading priorities. Render opening hours from `content/_index.md` in two places: a semantic homepage table and a compact footer text block.

**Tech Stack:** Hugo templates, front matter in Markdown, local static assets, vanilla JS, CSS, PowerShell verification script.

---

### Task 1: Make The Verifier Catch The New Homepage Structure

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Write the failing test**

Add assertions for:
- homepage hero no longer contains the old opening-hours block
- homepage contains an opening-hours table section below the cards
- footer contains plain-text opening hours
- homepage card image paths use `webp`
- header menu toggle typography no longer depends on the old overlay-only special-case marker

**Step 2: Run test to verify it fails**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- `hugo --destination .test-public` passes
- verifier fails on the new homepage/header/opening-hours expectations

**Step 3: Commit**

```powershell
git add tests/verify_site.ps1
git commit -m "test: add homepage performance and hours checks"
```

### Task 2: Switch Homepage Cards To Valid WebP Sources

**Files:**
- Modify: `layouts/partials/site-mode.html`

**Step 1: Write the failing test**

Use the red verifier from Task 1 as the failing test for invalid homepage card image paths.

**Step 2: Run test to verify it fails**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier still reports homepage card path failures

**Step 3: Write minimal implementation**

Update the bike homepage card image paths in `layouts/partials/site-mode.html` so all active homepage cards use valid `webp` assets only.

**Step 4: Run test to verify it passes**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- homepage image-path failures disappear
- other new checks may still fail

**Step 5: Commit**

```powershell
git add layouts/partials/site-mode.html
git commit -m "fix: use webp homepage card images"
```

### Task 3: Reduce Homepage Image And Scroll Cost

**Files:**
- Modify: `layouts/partials/shared-hero.html`
- Modify: `layouts/index.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the remaining verifier failures plus manual inspection targets as the failing state:
- hero still owns the opening-hours block
- homepage cards still load without reduced priority
- homepage still has heavy homepage-only visual markers in CSS that the new verifier flags

**Step 2: Run test to verify it fails**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier fails on homepage structure/performance-related markers

**Step 3: Write minimal implementation**

Implement only the necessary performance-oriented changes:
- in `layouts/partials/shared-hero.html`, keep the hero image as the main page image and give it explicit high-priority loading attributes
- in `layouts/index.html`, give homepage card images lower priority and async decoding
- in `assets/css/style.css`, reduce homepage-only compositing cost by removing or simplifying expensive blur/glass effects on the homepage cards and opening-hours presentation, while preserving the existing visual direction

**Step 4: Run test to verify it passes**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- homepage structure/performance-related failures are reduced or cleared

**Step 5: Commit**

```powershell
git add layouts/partials/shared-hero.html layouts/index.html assets/css/style.css
git commit -m "perf: optimize homepage image loading and scroll cost"
```

### Task 4: Unify Header Menu Typography

**Files:**
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the verifier’s header-toggle typography failure from Task 1 as the failing test.

**Step 2: Run test to verify it fails**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier still reports header menu typography mismatch

**Step 3: Write minimal implementation**

In `assets/css/style.css`:
- remove the overlay-only menu-toggle typography override that changes font-size/family/variant
- ensure `.site-nav__menu-toggle`, `.site-nav__menu-label`, `.site-nav__item`, and the switch link share one common type treatment
- align the hamburger icon weight/spacing so it visually matches the adjacent nav items

**Step 4: Run test to verify it passes**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- header typography mismatch failure disappears

**Step 5: Commit**

```powershell
git add assets/css/style.css
git commit -m "fix: unify header menu typography"
```

### Task 5: Move Opening Hours Below The Home Cards

**Files:**
- Modify: `layouts/partials/shared-hero.html`
- Modify: `layouts/index.html`
- Modify: `content/_index.md`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the verifier’s opening-hours homepage failures from Task 1 as the failing test:
- opening hours still present in hero
- opening-hours table not yet present below cards

**Step 2: Run test to verify it fails**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier still reports missing homepage opening-hours table and/or hero placement issues

**Step 3: Write minimal implementation**

Implement the approved structure:
- remove the homepage opening-hours block from `layouts/partials/shared-hero.html`
- add a dedicated section below the homepage card grids in `layouts/index.html`
- render the hours as a semantic table from the existing `opening_hours` list in `content/_index.md`
- add only the CSS needed for the table presentation in `assets/css/style.css`

**Step 4: Run test to verify it passes**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- homepage table assertions pass
- hero no longer contains the opening-hours block

**Step 5: Commit**

```powershell
git add layouts/partials/shared-hero.html layouts/index.html content/_index.md assets/css/style.css
git commit -m "feat: move opening hours below homepage cards"
```

### Task 6: Add Plain-Text Opening Hours To The Footer

**Files:**
- Modify: `layouts/partials/footer.html`
- Modify: `assets/css/style.css`
- Test: `tests/verify_site.ps1`

**Step 1: Write the failing test**

Use the verifier’s footer-hours failure from Task 1 as the failing test.

**Step 2: Run test to verify it fails**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier reports missing footer opening-hours content

**Step 3: Write minimal implementation**

Add a compact hours block in `layouts/partials/footer.html` that reads the same opening-hours source used by the homepage and renders it as plain text only.

**Step 4: Run test to verify it passes**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- footer opening-hours assertions pass

**Step 5: Commit**

```powershell
git add layouts/partials/footer.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add opening hours to footer"
```

### Task 7: Final Verification

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

**Step 3: Commit**

```powershell
git add .
git commit -m "feat: optimize homepage and restructure opening hours"
```

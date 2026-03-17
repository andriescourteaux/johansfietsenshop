# Mode-Aware Header and Homepage Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add persistent bike/drive site modes that dynamically switch the header logo, homepage hero, header navigation, and `merken en verdelers` destination while keeping Home and Contact shared.

**Architecture:** Use Hugo template logic as the primary mode source, deriving mode from dedicated page routes first and shared-page query parameters second. Add two mode-specific `merken en verdelers` pages, update the shared header and homepage templates to render mode-specific assets and links, and add a very small client-side fallback to remember the last explicit mode on shared pages when no mode query exists.

**Tech Stack:** Hugo, Go template partials, Markdown content files, CSS, minimal client-side JavaScript, PowerShell verification script

---

### Task 1: Extend verification for mode-aware assets and links

**Files:**
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\contact\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\index.html`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it expects:

- bike-mode pages to reference `logo.png`
- drive-mode pages to reference `logo-drive.png`
- bike-mode homepage output to reference the bike hero asset
- drive-mode homepage output to reference `header_drive.jpg`
- bike-mode header output to include `Driveshop` and exclude `Bikeshop`
- drive-mode header output to include `Bikeshop` and exclude `Driveshop`
- `merken en verdelers` links to resolve to the correct bike or drive variant

Because shared pages depend on mode, update the verification strategy so it can validate separate generated outputs for bike-mode and drive-mode URLs.

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current templates still render a static logo, a static hero, and both shop links.

**Step 3: Write minimal implementation**

Only adjust the verification harness in `tests\verify_site.ps1`. Do not change templates yet.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL with missing mode-aware markers.

**Step 5: Commit**

```bash
git add tests/verify_site.ps1
git commit -m "test: add mode-aware site verification"
```

### Task 2: Add Hugo mode-resolution helper and dynamic header logo

**Files:**
- Create: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Modify: `K:\Coding\Site2\layouts\partials\header.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification already written and target these specific conditions:

- bike-mode header output references `/images/logo.png`
- drive-mode header output references `/images/logo-drive.png`
- bike-mode header output excludes the `Bikeshop` switch link
- drive-mode header output excludes the `Driveshop` switch link

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current header still contains the text brand and both shop links.

**Step 3: Write minimal implementation**

Create `layouts\partials\site-mode.html` with minimal helper logic that exposes:

- `mode`
- `isBike`
- `isDrive`
- `logoPath`
- `switchLabel`
- `switchHref`
- `merkenHref`
- `homeHref`
- `contactHref`

Update `layouts\partials\header.html` to:

- replace the text brand with a clickable `<img>` logo
- render `logo.png` in bike mode
- render `logo-drive.png` in drive mode
- show only the opposite shop switch link
- preserve mode in shared-page URLs

Add the minimal CSS needed for logo sizing and stable header alignment.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for the header logo and switch-link assertions.

**Step 5: Commit**

```bash
git add layouts/partials/site-mode.html layouts/partials/header.html assets/css/style.css
git commit -m "feat: add mode-aware header logo and switch link"
```

### Task 3: Make the homepage hero mode-aware

**Files:**
- Modify: `K:\Coding\Site2\layouts\index.html`
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the existing verification to assert:

- bike-mode homepage output references the bike hero asset
- drive-mode homepage output references `/images/header_drive.jpg`

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the homepage still uses one static hero asset.

**Step 3: Write minimal implementation**

Update the mode helper to expose `heroPath`, then update `layouts\index.html` to render the bike or drive hero image according to the active mode.

Do not change homepage copy or layout structure beyond the asset swap.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for hero asset assertions.

**Step 5: Commit**

```bash
git add layouts/index.html layouts/partials/site-mode.html assets/css/style.css
git commit -m "feat: add mode-aware homepage hero"
```

### Task 4: Split `merken en verdelers` into bike and drive variants

**Files:**
- Create: `K:\Coding\Site2\content\bikeshop\merken-en-verdelers.md`
- Create: `K:\Coding\Site2\content\driveshop\merken-en-verdelers.md`
- Modify: `K:\Coding\Site2\content\driveshop.md`
- Modify: `K:\Coding\Site2\content\bikeshop.md`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend verification so it expects:

- generated bike page at `bikeshop/merken-en-verdelers/index.html`
- generated drive page at `driveshop/merken-en-verdelers/index.html`
- bike-mode links to target the bike variant
- drive-mode links to target the drive variant
- both pages to contain distinct mode-appropriate headings or placeholder copy

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because only one shared `merken en verdelers` page exists today.

**Step 3: Write minimal implementation**

Create the two new content pages with distinct titles or body copy. Update shared rendering only as much as needed to support both pages cleanly. Update the mode helper so the header link points to the correct variant.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for mode-specific `merken en verdelers` routing and content assertions.

**Step 5: Commit**

```bash
git add content/bikeshop/merken-en-verdelers.md content/driveshop/merken-en-verdelers.md content/bikeshop.md content/driveshop.md layouts/_default/single.html layouts/partials/site-mode.html tests/verify_site.ps1
git commit -m "feat: split merken en verdelers by site mode"
```

### Task 5: Add shared-page mode persistence fallback

**Files:**
- Create: `K:\Coding\Site2\layouts\partials\mode-script.html`
- Modify: `K:\Coding\Site2\layouts\_default\baseof.html`
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend verification so shared-page HTML includes:

- mode-preserving Home and Contact links
- a marker for the client-side mode persistence script
- a default-safe fallback to bike mode when explicit mode is missing

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because no mode persistence script exists yet.

**Step 3: Write minimal implementation**

Create a small partial that:

- stores the most recent explicit mode
- restores that mode only on shared pages lacking an explicit mode query
- leaves dedicated shop pages untouched

Mount it in `layouts\_default\baseof.html` so it is available where needed.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for the shared-page mode persistence markers.

**Step 5: Commit**

```bash
git add layouts/partials/mode-script.html layouts/_default/baseof.html layouts/partials/site-mode.html tests/verify_site.ps1
git commit -m "feat: persist site mode on shared pages"
```

### Task 6: Final cleanup and full verification

**Files:**
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Tighten final verification so it checks:

- logo sizing classes or selectors exist for stable header layout
- the mode-specific image paths are present in generated output
- both `merken en verdelers` pages are generated
- shared-page links preserve the active mode

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL until final polish is present.

**Step 3: Write minimal implementation**

Add only the remaining CSS cleanup and any final link or template polish needed to satisfy the final assertions without changing approved behavior.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS.

Also run a clean production build:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add assets/css/style.css tests/verify_site.ps1
git commit -m "feat: finalize mode-aware header and homepage"
```

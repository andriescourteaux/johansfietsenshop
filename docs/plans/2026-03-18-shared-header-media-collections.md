# Shared Header En Media-Collecties Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Voeg mode-specifieke mediacollecties toe voor leasing, accessoires en modellen in de kijker, breid de gedeelde header uit met een mode-aware hamburgermenu, en geef de homepage beeldgedreven kaarten met overlaytitels.

**Architecture:** De bestaande Hugo-mode-architectuur blijft leidend. `site-mode.html` wordt de centrale bron voor homecards, hamburgerlinks en kaartafbeeldingen, terwijl één generieke collectie-partial verschillende presentatiemodi ondersteunt voor logo-grids en hover-cards op basis van mode-specifieke afbeeldingsmappen en TOML-metadata.

**Tech Stack:** Hugo, Go templates, Markdown front matter, Hugo data files, CSS, vanilla JavaScript, PowerShell verification script

---

### Task 1: Breid verificatie uit voor gedeelde header, hamburgermenu, homecard-afbeeldingen en nieuwe collectiepagina's

**Files:**
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\contact\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\leasing-fietsen\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\accessoires\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\modellen-in-de-kijker\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\modellen-in-de-kijker\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\winteronderhoud-van-tuinmachines\index.html`
- Test: `K:\Coding\Site2\assets\css\style.css`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it expects:
- the same shared header markers on home and single pages
- a hamburger trigger and menu container in the header
- bike-specific menu entries for `merken en verdelers`, `accessoires`, `enkele modellen in de kijker`, and `leasing fietsen`
- drive-specific menu entries for `merken en verdelers`, `modellen in de kijker`, and `winteronderhoud van tuinmachines`
- homepage cards with image markers and overlay-title markup
- leasing, accessories, and models pages to render collection wrappers appropriate to their variants
- `winteronderhoud van tuinmachines` to remain a plain content page without collection markers
- the new collection source folders and data files to exist

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current header has no hamburger menu, the homepage cards have no image layer, and the new collection variants do not exist yet.

**Step 3: Write minimal implementation**

Update only the verification harness. Do not change templates, content, CSS, or JS yet.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL with missing header-menu, homecard-image, and collection markers.

**Step 5: Commit**

```bash
git add tests/verify_site.ps1
git commit -m "test: verify media collections and header menu"
```

### Task 2: Centralize hamburger-menu and image-backed homecard data in the mode helper

**Files:**
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- centralized bike and drive menu collections exist in the mode helper
- centralized bike and drive homepage cards include image paths
- winteronderhoud remains in drive menu data only
- leasing appears only in bike menu data

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because `site-mode.html` does not yet provide menu data or image-backed card data.

**Step 3: Write minimal implementation**

Update `layouts/partials/site-mode.html` so it exposes:
- bike and drive menu collections for the hamburger menu
- bike and drive home card collections with `title`, `summary`, `href`, and `image`
- exact mode-aware links for all relevant bike and drive pages

Keep existing `contact`, `switch`, `hero`, and logo data intact.

**Step 4: Run test to verify it partially passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: header-menu and card-image checks still fail, but central link destinations are ready for the next task.

**Step 5: Commit**

```bash
git add layouts/partials/site-mode.html tests/verify_site.ps1
git commit -m "feat: centralize mode-aware menu and card data"
```

### Task 3: Extend the shared header with a mode-aware hamburgermenu

**Files:**
- Modify: `K:\Coding\Site2\layouts\partials\header.html`
- Modify: `K:\Coding\Site2\layouts\partials\mode-script.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- the shared header renders the same menu trigger and menu container on home and single pages
- the menu renders bike or drive entries from centralized mode data
- the menu trigger is present next to `Contact` and the mode switch
- the mode script can open and close the menu and refresh menu links when the mode changes on shared pages

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the shared header has no hamburger-menu markup or behavior.

**Step 3: Write minimal implementation**

Update `layouts/partials/header.html` to render:
- a hamburger button with accessible attributes
- a menu container
- mode-aware bike and drive menu lists, using data from `site-mode.html`

Update `layouts/partials/mode-script.html` to:
- toggle the menu open and closed
- switch the visible menu list based on active mode
- keep the header shared on home and single pages without separate header variants

Update `assets/css/style.css` to style the hamburger button, menu panel, menu links, and mobile-friendly drop-down behavior.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for shared-header and hamburgermenu checks.

**Step 5: Commit**

```bash
git add layouts/partials/header.html layouts/partials/mode-script.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add mode-aware header menu"
```

### Task 4: Add collection scaffolding and front matter for leasing, accessories, and models pages

**Files:**
- Create: `K:\Coding\Site2\static\images\collecties\bikeshop\merken-en-verdelers\.gitkeep`
- Create: `K:\Coding\Site2\static\images\collecties\bikeshop\leasing-fietsen\.gitkeep`
- Create: `K:\Coding\Site2\static\images\collecties\bikeshop\accessoires\.gitkeep`
- Create: `K:\Coding\Site2\static\images\collecties\bikeshop\modellen-in-de-kijker\.gitkeep`
- Create: `K:\Coding\Site2\static\images\collecties\driveshop\merken-en-verdelers\.gitkeep`
- Create: `K:\Coding\Site2\static\images\collecties\driveshop\modellen-in-de-kijker\.gitkeep`
- Create: `K:\Coding\Site2\data\collecties\bikeshop\merken-en-verdelers.toml`
- Create: `K:\Coding\Site2\data\collecties\bikeshop\leasing-fietsen.toml`
- Create: `K:\Coding\Site2\data\collecties\bikeshop\accessoires.toml`
- Create: `K:\Coding\Site2\data\collecties\bikeshop\modellen-in-de-kijker.toml`
- Create: `K:\Coding\Site2\data\collecties\driveshop\merken-en-verdelers.toml`
- Create: `K:\Coding\Site2\data\collecties\driveshop\modellen-in-de-kijker.toml`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers-bikeshop.md`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers-driveshop.md`
- Modify: `K:\Coding\Site2\content\bikeshop\leasing-fietsen.md`
- Modify: `K:\Coding\Site2\content\bikeshop\accessoires.md`
- Modify: `K:\Coding\Site2\content\bikeshop\modellen-in-de-kijker.md`
- Modify: `K:\Coding\Site2\content\driveshop\modellen-in-de-kijker.md`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- all new collection directories and data files exist
- the affected content files declare collection mode, data key, and collection variant in front matter
- `winteronderhoud van tuinmachines` remains unchanged as a normal content page

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the collection scaffolding and front matter do not yet exist.

**Step 3: Write minimal implementation**

Create minimal collection data files using:
```toml
[items]
```

Update front matter in the relevant content files to include fields such as:
```toml
collection_mode = 'bikeshop'
collection_key = 'leasing-fietsen'
collection_variant = 'brand-links'
collection_filters = false
```

For `accessoires` and `modellen-in-de-kijker`, set `collection_variant = 'hover-cards'`.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for collection scaffolding and front-matter checks.

**Step 5: Commit**

```bash
git add static/images/collecties data/collecties content/merken-en-verdelers-bikeshop.md content/merken-en-verdelers-driveshop.md content/bikeshop/leasing-fietsen.md content/bikeshop/accessoires.md content/bikeshop/modellen-in-de-kijker.md content/driveshop/modellen-in-de-kijker.md tests/verify_site.ps1
git commit -m "feat: add media collection scaffolding"
```

### Task 5: Replace the specialized merken renderer with a generic collection partial

**Files:**
- Create: `K:\Coding\Site2\layouts\partials\media-collection.html`
- Delete: `K:\Coding\Site2\layouts\partials\merken-gallery.html`
- Delete: `K:\Coding\Site2\layouts\partials\merken-gallery-script.html`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- the generic collection wrapper renders on merken, leasing, accessories, and models pages
- `brand-links` pages render a link-friendly grid
- `hover-cards` pages render overlay-capable card markup
- `winteronderhoud` does not render the collection wrapper

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current renderer is still specialized for merken-only behavior.

**Step 3: Write minimal implementation**

Create `layouts/partials/media-collection.html` that:
- reads the correct collection folder from `collection_mode` and `collection_key`
- merges image files with metadata from `site.Data.collecties`
- sorts by `weight`, then filename
- renders `brand-links` markup for logo grids
- renders `hover-cards` markup for photo grids with overlay title shell
- conditionally renders filters only when `collection_filters = true`

Update `layouts/_default/single.html` so pages with collection front matter use `media-collection.html` instead of the old merken-specific partials.

Delete the old merken-specific partials only after the generic version covers their behavior.

**Step 4: Run test to verify it partially passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: collection pages render, but CSS and filter interactions may still be incomplete until the next tasks.

**Step 5: Commit**

```bash
git add layouts/partials/media-collection.html layouts/_default/single.html tests/verify_site.ps1
git rm layouts/partials/merken-gallery.html layouts/partials/merken-gallery-script.html
git commit -m "feat: generalize collection rendering"
```

### Task 6: Restore filtering only for merken pages and add hover-card overlays for accessories and models

**Files:**
- Modify: `K:\Coding\Site2\layouts\partials\media-collection.html`
- Create: `K:\Coding\Site2\layouts\partials\media-collection-script.html`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- filter buttons render only for `merken en verdelers`
- `leasing fietsen` renders a brand-links grid without filter controls
- accessories and models render hover-title overlays
- optional `url` remains supported in hover-card metadata
- gallery CSS includes both logo-grid and hover-card styles

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because filters and variant-specific styling/behavior are not fully wired yet.

**Step 3: Write minimal implementation**

Update `layouts/partials/media-collection.html` to:
- render filters only when `collection_filters` is true
- render overlay title markup for `hover-cards`
- preserve `target="_blank"` and `rel="noopener noreferrer"` on external URLs when present

Create `layouts/partials/media-collection-script.html` with:
- merken-page OR-filter behavior using `data-tags`
- no-op behavior on pages without filters

Update `layouts/_default/single.html` to include the script partial only on collection pages.

Update `assets/css/style.css` to define:
- `.media-collection`
- `.media-collection__filters`
- `.media-collection__grid--brand-links`
- `.media-collection__grid--hover-cards`
- `.media-collection__overlay`
- hover states, aspect ratios, and responsive grid collapse

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for collection-variant, filtering, and overlay checks.

**Step 5: Commit**

```bash
git add layouts/partials/media-collection.html layouts/partials/media-collection-script.html layouts/_default/single.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add media collection variants"
```

### Task 7: Add image-backed homepage cards with overlay titles

**Files:**
- Modify: `K:\Coding\Site2\layouts\index.html`
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- each homepage card renders an image marker and overlay title shell
- bike and drive card sets use different image sources where configured
- card titles match the existing mode-aware card titles
- the grid remains responsive for four-card and three-card modes

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current cards remain text blocks without image markup.

**Step 3: Write minimal implementation**

Update `layouts/partials/site-mode.html` so each bike and drive card item includes an `image` field.

Update `layouts/index.html` to render cards as image-backed links, for example:

```go-html-template
<a class="overview-card" href="{{ .href }}">
  <div class="overview-card__media">
    <img src="{{ .image }}" alt="" loading="lazy">
  </div>
  <div class="overview-card__overlay">
    <h2>{{ .title }}</h2>
    <p>{{ .summary }}</p>
  </div>
</a>
```

Update `assets/css/style.css` so cards support layered images, title overlays, and responsive behavior without losing the sober visual direction.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for homepage image-card checks.

Also run:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add layouts/index.html layouts/partials/site-mode.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add image-backed home cards"
```

### Task 8: Run end-to-end verification and review the rendered pages manually

**Files:**
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\leasing-fietsen\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\accessoires\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\modellen-in-de-kijker\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\modellen-in-de-kijker\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\winteronderhoud-van-tuinmachines\index.html`

**Step 1: Run the automated build verification**

Run: `hugo --destination .test-public`

Expected: exit code 0.

**Step 2: Run the site verification script**

Run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: `All site verification checks passed.`

**Step 3: Run the production build**

Run: `hugo`

Expected: exit code 0.

**Step 4: Perform manual browser checks**

Confirm:
- the header is identical on home, contact, merken, accessories, leasing, and model pages because it still comes from the shared partial
- the hamburger menu opens and shows the correct bike or drive links for the active mode
- bike leasing renders a logo-style grid with external links but no filter bar
- bike accessories renders hover-title cards
- bike and drive models render hover-title cards
- winteronderhoud remains a normal content page without collection markup
- homepage cards show image backgrounds and overlay titles

**Step 5: Commit**

No commit is required if verification passes without further code changes. If a last-minute verification fix is needed, commit only the exact files touched by that fix and avoid broad staging commands in this dirty worktree.

# Mode-Aware Homeflow En Filterbare Merken Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Vereenvoudig de header, maak de homepage per modus de centrale navigatie-ingang met mode-specifieke landingskaarten, en breid `merken en verdelers` uit met een nette filterbare grid en optionele externe merklinks.

**Architecture:** De wijziging blijft binnen de bestaande Hugo-structuur. De mode-logica blijft centraal in `layouts/partials/site-mode.html`, de homepage rendeert per modus een andere set kaartdata, nieuwe landingpagina's leven als gewone Markdown-content, en de merkengrid combineert statische afbeeldingsmappen met TOML-metadata en lichte client-side filtering.

**Tech Stack:** Hugo, Go templates, Markdown front matter, Hugo data files, CSS, vanilla JavaScript, PowerShell verification script

---

### Task 1: Breid de verificatie uit voor minimale header, mode-specifieke homepagekaarten en filterbare merken

**Files:**
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\contact\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\merken-en-verdelers\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\merken-en-verdelers\index.html`
- Test: `K:\Coding\Site2\assets\css\style.css`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it expects:
- the header nav to expose `Contact` and exactly one mode-switch item, but not `Merken en verdelers`
- the homepage to render four bike cards and three drive cards through mode-specific markers
- the new page URLs to exist in the generated output
- the merken pages to render a filter bar, grid items with `data-tags`, and optional external links
- the gallery CSS to define a three-column desktop grid and uniform image containers

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current templates still expose `Merken en verdelers` in the header, the homepage cards are not mode-specific, and the gallery has no filtering markup.

**Step 3: Write minimal implementation**

Update only the verification harness. Do not change templates, content, CSS, or JS yet.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL with missing navigation, card-set, and gallery filter markers.

**Step 5: Commit**

```bash
git add tests/verify_site.ps1
git commit -m "test: verify mode-specific homeflow"
```

### Task 2: Simplify the header and centralize all mode-aware destinations

**Files:**
- Modify: `K:\Coding\Site2\layouts\partials\header.html`
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- header output contains `Contact`
- header output contains the mode switch with correct bike/drive hrefs
- header output no longer contains the visible `Merken en verdelers` navigation item
- mode-aware destinations for all new home cards exist centrally in `site-mode.html`

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the old header still exposes extra navigation and `site-mode.html` does not yet surface all new landing-page hrefs.

**Step 3: Write minimal implementation**

Update `layouts/partials/site-mode.html` to provide centralized hrefs for:
- bike home and drive home
- contact
- bike merken en verdelers
- drive merken en verdelers
- bike accessoires
- bike modellen in de kijker
- bike leasing fietsen
- drive modellen in de kijker
- drive winteronderhoud van tuinmachines

Update `layouts/partials/header.html` so the nav renders only:
```go-html-template
<a class="site-nav__item site-nav__contact" href="{{ $siteMode.contactHref }}">Contact</a>
<a class="site-nav__item site-nav__switch" href="{{ $siteMode.switchHref }}">{{ $siteMode.switchLabel }}</a>
```

Keep the brand logo clickable to the current mode-aware homepage.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for the header checks.

**Step 5: Commit**

```bash
git add layouts/partials/header.html layouts/partials/site-mode.html tests/verify_site.ps1
git commit -m "feat: simplify mode-aware header"
```

### Task 3: Add the new bike and drive landing pages as content

**Files:**
- Create: `K:\Coding\Site2\content\bikeshop\accessoires.md`
- Create: `K:\Coding\Site2\content\bikeshop\modellen-in-de-kijker.md`
- Create: `K:\Coding\Site2\content\bikeshop\leasing-fietsen.md`
- Create: `K:\Coding\Site2\content\driveshop\modellen-in-de-kijker.md`
- Create: `K:\Coding\Site2\content\driveshop\winteronderhoud-van-tuinmachines.md`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers-bikeshop.md`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers-driveshop.md`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- each new bike and drive URL builds successfully
- existing merken pages retain their target URLs
- page titles for the new landing pages are present in the output

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the new content pages do not exist yet.

**Step 3: Write minimal implementation**

Create the new content files with minimal front matter and sober placeholder body copy, for example:

```toml
+++
title = 'Accessoires'
draft = false
url = '/bikeshop/accessoires/'
+++
```

```toml
+++
title = 'Winteronderhoud van tuinmachines'
draft = false
url = '/driveshop/winteronderhoud-van-tuinmachines/'
+++
```

Preserve the existing `merken en verdelers` files and only adjust params if the updated gallery needs extra front matter.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for the new page existence checks.

**Step 5: Commit**

```bash
git add content/bikeshop content/driveshop content/merken-en-verdelers-bikeshop.md content/merken-en-verdelers-driveshop.md tests/verify_site.ps1
git commit -m "feat: add bike and drive landing pages"
```

### Task 4: Render mode-specific homepage cards from centralized card data

**Files:**
- Modify: `K:\Coding\Site2\layouts\index.html`
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- bike mode renders four cards with the required titles
- drive mode renders three cards with the required titles
- no homepage card links to `/bikeshop/` or `/driveshop/` standalone pages
- the grid remains responsive and supports both 4-card and 3-card layouts cleanly

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current homepage still renders the old generic cards.

**Step 3: Write minimal implementation**

In `layouts/partials/site-mode.html`, expose two card collections or equivalent href/title helpers for bike and drive mode.

Update `layouts/index.html` to select the correct collection by active mode and render cards from data like:

```go-html-template
{{- $cards := cond $siteMode.isDrive $siteMode.driveCards $siteMode.bikeCards -}}
{{ range $cards }}
<a class="overview-card" href="{{ .href }}">
  <h2>{{ .title }}</h2>
  <p>{{ .summary }}</p>
</a>
{{ end }}
```

Update `assets/css/style.css` so the home overview grid supports 3 or 4 cards without awkward spacing, while preserving the sober visual style.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for the homepage card and link checks.

Also run:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add layouts/index.html layouts/partials/site-mode.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add mode-specific home cards"
```

### Task 5: Extend the gallery metadata model with tags, links, and safe defaults

**Files:**
- Modify: `K:\Coding\Site2\data\merken-verdelers\bikeshop.toml`
- Modify: `K:\Coding\Site2\data\merken-verdelers\driveshop.toml`
- Modify: `K:\Coding\Site2\layouts\partials\merken-gallery.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- metadata supports `tags`, `url`, `alt`, and `weight`
- gallery items render `data-tags`
- items with a `url` render as links
- items without a `url` stay visible without external-link markup

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current metadata contract and gallery partial do not yet expose tag or link behavior.

**Step 3: Write minimal implementation**

Update the data files with sample structure such as:

```toml
[items."gazelle.png"]
title = "Gazelle"
alt = "Gazelle logo"
tags = ["stadsfiets", "elektrische fiets"]
url = "https://www.gazelle.nl/"
weight = 10
```

Update `layouts/partials/merken-gallery.html` so it:
- merges image files with metadata by filename
- sorts by `weight` and then filename
- writes `data-tags="stadsfiets|elektrische fiets"` or equivalent
- wraps the image in an anchor when `url` exists
- applies `target="_blank"` and `rel="noopener noreferrer"` to external links

Keep visible output limited to the images only.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for metadata and external-link checks.

**Step 5: Commit**

```bash
git add data/merken-verdelers layouts/partials/merken-gallery.html tests/verify_site.ps1
git commit -m "feat: add metadata-driven brand links"
```

### Task 6: Add multi-tag filter controls and the refined three-column gallery layout

**Files:**
- Modify: `K:\Coding\Site2\layouts\partials\merken-gallery.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Create: `K:\Coding\Site2\layouts\partials\merken-gallery-script.html`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- the page renders an `Alles` filter button
- unique tag buttons render above the grid
- the desktop CSS declares a three-column grid
- gallery items use a consistent card and image container structure
- the single template includes the filter script only on gallery pages

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because no filter UI or gallery script exists yet.

**Step 3: Write minimal implementation**

Update `layouts/partials/merken-gallery.html` to:
- collect unique tags from all metadata
- render a filter bar before the grid
- render items with stable selectors like `data-merken-item`

Create `layouts/partials/merken-gallery-script.html` with minimal JS:

```html
<script>
document.addEventListener('DOMContentLoaded', function () {
  const root = document.querySelector('[data-merken-gallery]');
  if (!root) return;
});
</script>
```

Expand it to:
- toggle selected tag buttons
- show all items when no tag is active or `Alles` is chosen
- apply `OR` logic when multiple tags are active
- hide non-matching items without reloading the page

Update `layouts/_default/single.html` so gallery pages include the script partial once.

Update `assets/css/style.css` for:
- `.merken-gallery__filters`
- `.merken-gallery__filter`
- active and inactive button states
- a strict three-column desktop grid
- responsive collapse to two and one columns
- uniform image containers using `aspect-ratio`, `object-fit`, centered content, and restrained spacing

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS.

Also run:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add layouts/partials/merken-gallery.html layouts/partials/merken-gallery-script.html layouts/_default/single.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add multi-tag brand filtering"
```

### Task 7: Run end-to-end verification and review the rendered pages manually

**Files:**
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\accessoires\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\merken-en-verdelers\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\merken-en-verdelers\index.html`
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
- bike mode homepage shows four correct cards
- drive mode homepage shows three correct cards
- header only shows `Contact` and the opposite mode switch
- `Merken en verdelers` pages show the filter bar and three-column layout on desktop
- multiple tags together broaden results using `OR`
- items with `url` open the brand site in a new tab
- items without `url` remain visible and non-clickable

**Step 5: Commit**

No commit is required if verification passes without further code changes. If a last-minute verification fix is needed, commit only the exact files touched by that fix and avoid broad staging commands in this dirty worktree.


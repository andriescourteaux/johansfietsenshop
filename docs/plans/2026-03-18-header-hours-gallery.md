# Header, Openingsuren En Gallery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Maak de headertypografie consistent met de homepage, voeg content-gedreven openingsuren toe aan de homepage, en laat de bike- en drive-versies van `merken en verdelers` een dynamische afbeeldingsgallery uit mappen renderen.

**Architecture:** De wijziging blijft binnen de bestaande Hugo-templatestructuur. Header- en homepage-aanpassingen gebeuren in de bestaande CSS en homepage-content, terwijl de merken/verdelersgallery via een nieuwe partial en mode-specifieke contentparams uit `static/images/merken-verdelers/*` leest, met uitbreidbare metadata uit `data/merken-verdelers/*`.

**Tech Stack:** Hugo, Go templates, Markdown front matter, Hugo data files, CSS, PowerShell verification script

---

### Task 1: Breid verificatie uit voor headerconsistentie, openingsuren en gallery-hooks

**Files:**
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\merken-en-verdelers\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\merken-en-verdelers\index.html`
- Test: `K:\Coding\Site2\assets\css\style.css`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it expects:
- a homepage opening-hours block marker such as `opening-hours`
- the three homepage opening-hours lines rendered from content
- shared header typography markers in `assets/css/style.css`
- a gallery wrapper marker on bike and drive `merken en verdelers`
- the old placeholder brand/dealer cards to no longer be required on those mode-specific pages
- the existence of `static/images/merken-verdelers/bikeshop` and `static/images/merken-verdelers/driveshop`

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the homepage does not yet render opening hours and the mode-specific pages still use placeholder content instead of the gallery hook.

**Step 3: Write minimal implementation**

Update only the verification harness. Do not change templates or content yet.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL with missing opening-hours and gallery markers.

**Step 5: Commit**

```bash
git add tests/verify_site.ps1
git commit -m "test: verify hours and gallery layout"
```

### Task 2: Make homepage opening hours content-driven and align header typography

**Files:**
- Modify: `K:\Coding\Site2\content\_index.md`
- Modify: `K:\Coding\Site2\layouts\index.html`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- the homepage reads opening hours from `content/_index.md`
- the opening-hours block appears between the hero intro label and title
- normal page headers use the same navigation typography treatment as the homepage header

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the content model and styles do not yet render the new block and shared typography.

**Step 3: Write minimal implementation**

Update `content/_index.md` with dedicated front matter, for example:
```toml
opening_hours_title = 'Openingsuren'
opening_hours = [
  'Zondag en maandag gesloten',
  'Dinsdag tot zaterdag: 9u tot 17u',
  'Middagpauze voorzien'
]
```

Update `layouts/index.html` to render a dedicated block such as:
```go-html-template
{{ if .Params.opening_hours }}
<div class="opening-hours">
  <p class="opening-hours__title">{{ .Params.opening_hours_title }}</p>
  <ul class="opening-hours__list">
    {{ range .Params.opening_hours }}
    <li>{{ . }}</li>
    {{ end }}
  </ul>
</div>
{{ end }}
```

Update `assets/css/style.css` so the header navigation typography is defined centrally for `.site-nav__item` and related header selectors, while keeping homepage-only layout behavior separate. Add sober styling for `.opening-hours`, `.opening-hours__title`, and `.opening-hours__list`.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for the opening-hours and header-style checks.

**Step 5: Commit**

```bash
git add content/_index.md layouts/index.html assets/css/style.css tests/verify_site.ps1
git commit -m "feat: add content-driven opening hours"
```

### Task 3: Add gallery source folders and optional metadata structure

**Files:**
- Create: `K:\Coding\Site2\static\images\merken-verdelers\bikeshop\.gitkeep`
- Create: `K:\Coding\Site2\static\images\merken-verdelers\driveshop\.gitkeep`
- Create: `K:\Coding\Site2\data\merken-verdelers\bikeshop.toml`
- Create: `K:\Coding\Site2\data\merken-verdelers\driveshop.toml`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- the source directories exist in the repo
- optional metadata files exist for future filename-based text and alt handling

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the folders and data files do not yet exist.

**Step 3: Write minimal implementation**

Create empty source folders using tracked placeholders and add minimal metadata scaffolding, for example:
```toml
# data/merken-verdelers/bikeshop.toml
[items]
```

```toml
# data/merken-verdelers/driveshop.toml
[items]
```

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS for folder and metadata scaffolding checks.

**Step 5: Commit**

```bash
git add static/images/merken-verdelers data/merken-verdelers tests/verify_site.ps1
git commit -m "feat: add gallery source scaffolding"
```

### Task 4: Render mode-specific merken/verdelers galleries from image folders

**Files:**
- Create: `K:\Coding\Site2\layouts\partials\merken-gallery.html`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers-bikeshop.md`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers-driveshop.md`
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification and target these conditions:
- bike and drive `merken en verdelers` pages render a gallery wrapper such as `merken-gallery`
- image items render from the configured mode directory
- if the mode directory is empty, a fallback notice renders instead of the old brand/dealer card grid

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the single template still renders placeholder arrays.

**Step 3: Write minimal implementation**

Update `content/merken-en-verdelers-bikeshop.md` and `content/merken-en-verdelers-driveshop.md` with params such as:
```toml
gallery_mode = 'bikeshop'
gallery_data_key = 'bikeshop'
```
and
```toml
gallery_mode = 'driveshop'
gallery_data_key = 'driveshop'
```

Create `layouts/partials/merken-gallery.html` that:
- reads `static/images/merken-verdelers/{{ .Params.gallery_mode }}`
- filters files by image extension
- looks up optional metadata in `site.Data.merken-verdelers`
- renders a responsive image grid with only images visible
- falls back to a sober message if no images are found

Update `layouts/_default/single.html` so pages with `gallery_mode` render the gallery partial instead of the placeholder `brands` and `dealers` blocks.

Add CSS for `.merken-gallery`, `.merken-gallery__grid`, `.merken-gallery__item`, `.merken-gallery__image`, and the fallback state.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS.

Also run:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add layouts/partials/merken-gallery.html layouts/_default/single.html content/merken-en-verdelers-bikeshop.md content/merken-en-verdelers-driveshop.md assets/css/style.css tests/verify_site.ps1
git commit -m "feat: render mode-specific merken galleries"
```

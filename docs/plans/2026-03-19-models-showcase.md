# Models Showcase Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current simple models grids with richer alternating scroll showcases on both bike and drive `modellen in de kijker` pages.

**Architecture:** Extend the existing media collection system with a dedicated `showcase` variant instead of introducing a separate page system. Keep the existing collection directories and TOML data files, but enrich the models metadata so the renderer can output alternating image-and-spec sections.

**Tech Stack:** Hugo templates, Hugo TOML data files, local CSS, PowerShell verifier, git workflow.

---

### Task 1: Lock the verifier onto the new showcase behavior first

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Add failing checks for models showcase output**

Update the verifier so it checks:
- bike and drive models pages render a showcase root marker
- showcase items contain intro text hooks
- showcase items contain specs list hooks
- alternating layout hooks exist
- non-model collection variants still render their current markers

**Step 2: Run the verifier to confirm it fails first**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: FAIL because the showcase variant does not exist yet.

### Task 2: Point the models pages to the new collection variant

**Files:**
- Modify: `content/bikeshop/modellen-in-de-kijker.md`
- Modify: `content/driveshop/modellen-in-de-kijker.md`

**Step 1: Set the collection variant**

Add or update front matter so both pages use:

```toml
collection_variant = "showcase"
```

**Step 2: Re-run the verifier**

Expected: page wiring checks may pass, while showcase rendering checks still fail.

### Task 3: Enrich the models metadata

**Files:**
- Modify: `data/collecties/bikeshop/modellen-in-de-kijker.toml`
- Modify: `data/collecties/driveshop/modellen-in-de-kijker.toml`

**Step 1: Add richer content fields per model**

Support and populate:
- `title`
- `alt`
- `image`
- `intro`
- `specs = []`
- optional `url`

Keep the current item ordering from the data file rather than introducing a `weight` field for this variant.

**Step 2: Re-run the verifier**

Expected: data is ready, but showcase markup checks still fail until the renderer exists.

### Task 4: Implement the showcase renderer in the media collection partial

**Files:**
- Modify: `layouts/partials/media-collection.html`

**Step 1: Add a `showcase` branch**

When `collection_variant == "showcase"`, render:
- a showcase root wrapper
- one showcase section per item
- alternating layout hooks per item index
- image block
- info block with title, intro, specs, optional link

Do not change the behavior of `brand-links` or `hover-cards`.

**Step 2: Re-run the verifier**

Expected: output checks start passing, layout/style checks may still fail.

### Task 5: Add showcase styling and responsive behavior

**Files:**
- Modify: `assets/css/style.css`

**Step 1: Add showcase layout styles**

Style for:
- two-column desktop layout
- alternating left/right placement per item
- stacked mobile layout
- model title, intro, specs hierarchy
- light reveal polish without heavy motion cost

**Step 2: Re-run full verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
hugo
```

Expected: all commands pass.

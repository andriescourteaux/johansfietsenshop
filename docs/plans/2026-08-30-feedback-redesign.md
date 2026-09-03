# Feedback Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Apply the `feedback/feedback-revised.md` site redesign to the Hugo site with shared split-block layouts, updated content, and verified output.

**Architecture:** Reuse the current Hugo structure: content files define pages, TOML data defines repeated cards/collections, partials render shared layout, and one CSS file styles everything. Add one `split-blocks` collection variant and one homepage data file instead of creating one-off templates for each page.

**Tech Stack:** Hugo, TOML data files, Go template partials, plain CSS, PowerShell verification.

---

### Task 1: Protect Current Behavior With Failing Checks

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Add failing assertions**

Add checks for the new target behavior:

```powershell
Assert-Matches $driveBrandsHtml '(?is)<body\b[^>]*data-site-mode="drive"' 'driveshop/merken-en-verdelers drive mode'
Assert-Matches $driveModelsHtml '(?is)<body\b[^>]*data-site-mode="drive"' 'driveshop/modellen-in-de-kijker drive mode'
Assert-NotMatches $homeHtml '(?is)<section\b[^>]*class="[^"]*\bopening-hours-section\b' 'index.html opening hours moved'
Assert-NotMatches $contactHtml '(?is)<form\b[^>]*class="[^"]*\bcontact-form\b' 'contact form removed'
Assert-Contains $contactHtml 'Vragen, een nieuwe fiets kopen of onderhoud nodig?' 'contact intro'
Assert-Contains $homeHtml 'Start een nieuw avontuur' 'bike homepage title'
Assert-Contains $homeHtml 'Geniet van een perfect verzorgde tuin.' 'drive homepage title hook'
Assert-Contains $bikeBrandsHtml 'Onze merken' 'bike brands title'
Assert-NotContains $bikeBrandsHtml 'data-media-filter=' 'bike brands filters disabled'
Assert-Contains $bikeBrandsHtml 'media-collection--split-blocks' 'bike brands split blocks'
Assert-Contains $driveBrandsHtml 'media-collection--split-blocks' 'drive brands split blocks'
Assert-Contains $contactHtml 'Betaal mogelijkheden' 'contact payment methods'
Assert-Contains $contactHtml 'Vervangfiets' 'contact replacement bike block'
Assert-Contains $contactHtml 'Ophaaldienst' 'contact pickup block'
Assert-Contains $winterHtml 'Maak je tuinmachines winterklaar' 'winter maintenance title'
Assert-Contains $winterHtml 'Neem contact op' 'winter contact CTA'
```

Also add `$winterHtml` and `$aboutHtml` readers near the other generated-page reads:

```powershell
$winterHtml = Read-GeneratedText 'driveshop/winteronderhoud-van-tuinmachines/index.html'
$aboutHtml = Read-GeneratedText 'over-ons/index.html'
```

**Step 2: Run and confirm failure**

Run:

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: FAIL on new assertions.

**Step 3: Commit**

```bash
git add tests/verify_site.ps1
git commit -m "test: capture feedback redesign expectations"
```

### Task 2: Fix Mode Detection Root Cause

**Files:**
- Modify: `layouts/partials/site-mode.html`

**Step 1: Replace brittle permalink detection**

Use `.File.Path` where present and fall back to `.RelPermalink`.

```go-html-template
{{- $path := "" -}}
{{- with .File -}}
  {{- $path = .Path -}}
{{- end -}}
{{- $rel := .RelPermalink -}}
{{- $mode := "bike" -}}
{{- $isShared := true -}}

{{- if or (hasPrefix $path "driveshop") (hasPrefix $rel "/driveshop/") (hasPrefix $rel "driveshop/") -}}
  {{- $mode = "drive" -}}
  {{- $isShared = false -}}
{{- else if or (hasPrefix $path "bikeshop") (hasPrefix $rel "/bikeshop/") (hasPrefix $rel "bikeshop/") -}}
  {{- $mode = "bike" -}}
  {{- $isShared = false -}}
{{- end -}}
```

**Step 2: Run checks**

Run the same Hugo build and verifier.

Expected: drive mode assertions pass or move to later failures.

**Step 3: Commit**

```bash
git add layouts/partials/site-mode.html
git commit -m "fix: detect shop mode from content path"
```

### Task 3: Add Assets

**Files:**
- Create: `static/images/about/headshot.webp`
- Create: `static/images/home/advies.webp`
- Create: `static/images/collecties/bikeshop/accessoires/basil.jpg`
- Create: `static/images/collecties/bikeshop/accessoires/vdb.jpg`
- Create: `static/images/collecties/bikeshop/accessoires/axa.webp`
- Create: `static/images/collecties/bikeshop/accessoires/lvw.jpg`
- Create: `static/images/collecties/bikeshop/accessoires/thule.jpg`
- Create: `static/images/collecties/bikeshop/leasing-fietsen/welease.svg`
- Create: `static/images/collecties/driveshop/merken-en-verdelers/vegemac_tb.webp`
- Create: `static/images/collecties/driveshop/merken-en-verdelers/iseki_tb.jpg`
- Create: `static/images/collecties/driveshop/merken-en-verdelers/castelgarden_tb.webp`
- Create: `static/images/collecties/driveshop/merken-en-verdelers/stiga_tb.png`
- Create: `static/images/collecties/driveshop/merken-en-verdelers/makita_tb.jpg`

**Step 1: Copy files**

Run:

```powershell
New-Item -ItemType Directory -Force static/images/about,static/images/home | Out-Null
Copy-Item feedback/headshot.webp static/images/about/headshot.webp -Force
Copy-Item feedback/advies.webp static/images/home/advies.webp -Force
Copy-Item feedback/basil.jpg static/images/collecties/bikeshop/accessoires/basil.jpg -Force
Copy-Item feedback/vdb.jpg static/images/collecties/bikeshop/accessoires/vdb.jpg -Force
Copy-Item feedback/axa.webp static/images/collecties/bikeshop/accessoires/axa.webp -Force
Copy-Item feedback/lvw.jpg static/images/collecties/bikeshop/accessoires/lvw.jpg -Force
Copy-Item feedback/thule.jpg static/images/collecties/bikeshop/accessoires/thule.jpg -Force
Copy-Item feedback/welease.svg static/images/collecties/bikeshop/leasing-fietsen/welease.svg -Force
Copy-Item feedback/vegemac_tb.webp static/images/collecties/driveshop/merken-en-verdelers/vegemac_tb.webp -Force
Copy-Item feedback/iseki_tb.jpg static/images/collecties/driveshop/merken-en-verdelers/iseki_tb.jpg -Force
Copy-Item feedback/castelgarden_tb.webp static/images/collecties/driveshop/merken-en-verdelers/castelgarden_tb.webp -Force
Copy-Item feedback/stiga_tb.png static/images/collecties/driveshop/merken-en-verdelers/stiga_tb.png -Force
Copy-Item feedback/makita_tb.jpg static/images/collecties/driveshop/merken-en-verdelers/makita_tb.jpg -Force
```

**Step 2: Commit**

```bash
git add static/images/about static/images/home static/images/collecties/bikeshop/accessoires static/images/collecties/bikeshop/leasing-fietsen/welease.svg static/images/collecties/driveshop/merken-en-verdelers
git commit -m "chore: add feedback image assets"
```

### Task 4: Update Shared Contact And Popup Data

**Files:**
- Modify: `data/contact.toml`
- Modify: `data/promo-popup.toml`
- Modify: `layouts/partials/promo-popup.html`
- Modify: `layouts/partials/footer.html`

**Step 1: Update contact data**

Use:

```toml
name = "Johan Alliet"
address = "Kalve 62, 9185 Wachtebeke"
maps_url = "https://www.google.com/maps?q=Kalve%2062%2C%209185%20Wachtebeke"
email = "info@johansfietsenshop.be"
phone = "0472 93 03 56"
instagram_url = ""
vat = "BE 0898284633"
```

Leave `instagram_url` empty unless the real URL is known. Render the line only when non-empty.

**Step 2: Update popup data**

Use:

```toml
enabled = true
image = "/images/promo/promo.webp"
alt = "Promotie"
title = "Voorkom startproblemen en dure herstellingen"
body = [
  "Wist je dat het jaarlijks onderhouden van je fiets en tuinmachines de levensduur aanzienlijk verlengt? Door stilstand in de winter of intensief gebruik in de zomer treden er ongemerkt slijtage en storingen op.",
  "Met een jaarlijkse controle zorg je voor betrouwbaarheid, veiligheid en waardebehoud."
]
bullets = [
  "Betrouwbaarheid: Altijd direct starten en soepel rijden.",
  "Veiligheid: Remmen, kettingen en messen in topconditie.",
  "Waardebehoud: Minder kans op onverwachte, dure kosten achteraf."
]
cta_label = "Maak nu een afspraak voor onderhoud"
cta_url = "/contact/"
```

**Step 3: Make popup image-first with text fallback**

In `layouts/partials/promo-popup.html`, render image markup when `image` is set; otherwise render title/body/bullets/CTA.

Use Hugo `fileExists` for local image paths:

```go-html-template
{{- $image := index . "image" -}}
{{- $hasImage := false -}}
{{- with $image -}}
  {{- $hasImage = fileExists (printf "static%s" .) -}}
{{- end -}}
```

**Step 4: Update footer**

Wrap address in link to `$contact.maps_url`, use `$contact.email`, `$contact.phone`, optional Instagram, VAT, and the extra closed-days line.

**Step 5: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add data/contact.toml data/promo-popup.toml layouts/partials/promo-popup.html layouts/partials/footer.html
git commit -m "feat: update popup and footer contact data"
```

### Task 5: Add Split-Blocks Collection Variant

**Files:**
- Modify: `layouts/partials/media-collection.html`
- Modify: `assets/css/style.css`

**Step 1: Add variant branch**

Before the existing `showcase` branch, add support for:

```go-html-template
{{- if eq $collectionVariant "split-blocks" -}}
  {{- if gt (len $items) 0 -}}
    <div class="split-blocks">
      {{- range $index, $item := $items -}}
      <article class="split-block{{ if eq (mod $index 2) 1 }} split-block--reverse{{ end }}">
        <div class="split-block__media">
          {{- if $item.url -}}<a class="split-block__media-link" href="{{ $item.url }}" target="_blank" rel="noopener noreferrer" aria-label="{{ $item.title }}">{{- end -}}
          <img class="split-block__image" src="{{ $item.src }}" alt="{{ $item.alt }}" loading="lazy">
          {{- if $item.url -}}</a>{{- end -}}
        </div>
        <div class="split-block__content">
          <h2 class="split-block__title">{{ $item.title }}</h2>
          {{- with $item.intro }}<p class="split-block__intro">{{ . }}</p>{{- end -}}
          {{- if and $item.url $item.button_label }}
          <a class="split-block__button" href="{{ $item.url }}" target="_blank" rel="noopener noreferrer">{{ $item.button_label }}</a>
          {{- end -}}
        </div>
      </article>
      {{- end -}}
    </div>
  {{- else -}}
    <p class="media-collection__empty">Afbeeldingen volgen binnenkort.</p>
  {{- end -}}
{{- else if eq $collectionVariant "showcase" -}}
```

Also collect `button_label` from metadata with:

```go-html-template
{{- $buttonLabel := "" -}}
{{- with .button_label -}}{{- $buttonLabel = . -}}{{- end -}}
```

Add it to each item dict as `"button_label" $buttonLabel`.

**Step 2: Add CSS**

Add:

```css
.split-blocks {
    display: grid;
    gap: 0;
}

.split-block {
    display: grid;
    grid-template-columns: 1fr 1fr;
    background: var(--surface);
}

.split-block--reverse .split-block__media {
    order: 2;
}

.split-block__media,
.split-block__media-link,
.split-block__image {
    min-height: 22rem;
}

.split-block__image {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.split-block__content {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    gap: 1rem;
    padding: clamp(2rem, 5vw, 4rem);
    text-align: center;
}

.split-block__button {
    padding: 0.85rem 1.1rem;
    background: var(--accent);
    color: var(--text);
    font-weight: 700;
    text-transform: uppercase;
}

@media (max-width: 760px) {
    .split-block {
        grid-template-columns: 1fr;
    }

    .split-block--reverse .split-block__media {
        order: 0;
    }
}
```

**Step 3: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add layouts/partials/media-collection.html assets/css/style.css
git commit -m "feat: add split block collection layout"
```

### Task 6: Update Collection Content And Data

**Files:**
- Modify: `content/merken-en-verdelers-bikeshop.md`
- Modify: `content/merken-en-verdelers-driveshop.md`
- Modify: `content/bikeshop/leasing-fietsen.md`
- Modify: `content/bikeshop/accessoires.md`
- Modify: `data/collecties/bikeshop/merken-en-verdelers.toml`
- Modify: `data/collecties/bikeshop/leasing-fietsen.toml`
- Modify: `data/collecties/bikeshop/accessoires.toml`
- Modify: `data/collecties/driveshop/merken-en-verdelers.toml`

**Step 1: Change front matter**

Set collection pages to:

```toml
collection_variant = 'split-blocks'
collection_filters = false
```

Set titles:

```toml
title = 'Onze merken'
```

For leasing:

```toml
title = 'Leasing'
```

Remove body copy from these four pages.

**Step 2: Update bike brand data**

Keep existing images and URLs. Add `intro` to each item from feedback. Keep weights in desired order.

**Step 3: Update leasing data**

Add descriptions and buttons:

```toml
button_label = "Meer informatie"
```

Add:

```toml
[items."welease.svg"]
title = "Welease"
alt = "Welease"
image = "/images/collecties/bikeshop/leasing-fietsen/welease.svg"
intro = "Op zoek naar een straffe fietsleasing? In 93% van de gevallen biedt welease de voordeligste fietsleasing formules."
url = "https://www.welease.be/"
button_label = "Meer informatie"
weight = 60
```

Update Velobility URL:

```toml
url = "https://www.cyclobility.be/nl"
```

**Step 4: Replace accessories data**

Use only:

- `basil.jpg`
- `vdb.jpg`
- `axa.webp`
- `lvw.jpg`
- `thule.jpg`

Each gets `title`, `alt`, `image`, `intro`, and `weight`.

**Step 5: Replace drive brand data**

Use:

- `vegemac_tb.webp`, Vegemac, `https://www.vegemac.be/nl`
- `iseki_tb.jpg`, Iseki, `https://www.iseki.co.jp/global/english/`
- `castelgarden_tb.webp`, Castelgarden, `https://www.castelgarden.com/be_nl/`
- `stiga_tb.png`, Stiga, existing Stiga URL
- `makita_tb.jpg`, Makita, `https://www.makita.be/`

**Step 6: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add content/merken-en-verdelers-bikeshop.md content/merken-en-verdelers-driveshop.md content/bikeshop/leasing-fietsen.md content/bikeshop/accessoires.md data/collecties
git commit -m "feat: refresh collection pages from feedback"
```

### Task 7: Update Home Page

**Files:**
- Create: `data/home.toml`
- Modify: `content/_index.md`
- Modify: `layouts/index.html`
- Modify: `layouts/partials/shared-hero.html`
- Modify: `layouts/partials/site-mode.html`
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Move hero copy into front matter or mode data**

In `content/_index.md`, remove `opening_hours` and use:

```toml
title = "Start een nieuw avontuur"
hero_title_bike = "Start een nieuw avontuur"
hero_title_drive = "Geniet van een perfect verzorgde tuin."
hero_intro_bike = "Herstelling van alle merken en verkoop van nieuwe fietsen"
hero_intro_drive = "Herstelling van alle merken en verkoop van nieuwe en tuinmachines"
```

**Step 2: Update shared hero**

Make `shared-hero.html` use mode-specific title when present:

```go-html-template
{{- $bikeHeroTitle := or $page.Params.hero_title_bike $page.Title -}}
{{- $driveHeroTitle := or $page.Params.hero_title_drive $bikeHeroTitle -}}
{{- $heroTitle := cond $siteMode.isDrive $driveHeroTitle $bikeHeroTitle -}}
```

Render:

```go-html-template
<h1 data-bike-title="{{ $bikeHeroTitle }}" data-drive-title="{{ $driveHeroTitle }}">{{ $heroTitle }}</h1>
```

Update `mode-script.html` to switch this text on shared pages.

**Step 3: Remove model cards from home/nav**

In `site-mode.html`, remove bike `models` from `$bikePanels` and `$bikeMenuItems`; remove drive `models` from `$drivePanels` and `$driveMenuItems`; rename brands title to `Onze merken`; rename winter menu/panel title to `Winteronderhoud`.

**Step 4: Add home data**

Create `data/home.toml` with bike and drive promo rows, quote text, and highlight references. Keep highlights as existing model collection items.

**Step 5: Render home sections**

In `layouts/index.html`, after cards:

- render bike split rows when active bike panel is shown.
- render drive split rows when active drive panel is shown.
- render quote.
- render highlights using existing collection data.

Do not re-add opening-hours markup.

**Step 6: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add data/home.toml content/_index.md layouts/index.html layouts/partials/shared-hero.html layouts/partials/site-mode.html layouts/partials/mode-script.html assets/css/style.css
git commit -m "feat: update mode-aware homepage"
```

### Task 8: Rebuild Contact Page

**Files:**
- Modify: `content/contact.md`
- Modify: `layouts/_default/single.html`
- Modify: `assets/css/style.css`

**Step 1: Update front matter**

Use:

```toml
title = 'Contact'
draft = false
showContactPage = true
```

Remove `showContactForm`.

**Step 2: Replace contact form branch**

In `single.html`, replace the `showContactForm` branch with `showContactPage`. Render:

- intro text
- two info blocks
- phone/email buttons
- opening-hours table from `site.Home.Params.opening_hours` unless those hours were moved into `data/contact.toml`
- payment logo placeholders
- existing map
- two lower service blocks

**Step 3: Add CSS**

Reuse existing `.contact-panel__map`; add small classes only for new block grids/buttons/payment logos.

**Step 4: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add content/contact.md layouts/_default/single.html assets/css/style.css
git commit -m "feat: rebuild contact page"
```

### Task 9: Add About Page

**Files:**
- Create: `content/over-ons.md`
- Modify: `layouts/_default/single.html`
- Modify: `layouts/partials/site-mode.html`
- Modify: `assets/css/style.css`

**Step 1: Create content**

Use front matter:

```toml
+++
title = 'Over ons'
draft = false
showAboutPage = true
+++
```

Keep the long about copy in the template branch or as Markdown body. Prefer Markdown body if it stays readable.

**Step 2: Render page**

Add `showAboutPage` branch in `single.html`:

- headshot/image left
- quote right
- centered vision block
- three value blocks
- highlights

**Step 3: Add menu link**

Add `Over ons` to both `$bikeMenuItems` and `$driveMenuItems` in `site-mode.html`.

**Step 4: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add content/over-ons.md layouts/_default/single.html layouts/partials/site-mode.html assets/css/style.css
git commit -m "feat: add about page"
```

### Task 10: Update Winter Maintenance Page

**Files:**
- Modify: `content/driveshop/winteronderhoud-van-tuinmachines.md`
- Modify: `layouts/_default/single.html`
- Modify: `assets/css/style.css`

**Step 1: Replace content**

Set title:

```toml
title = 'Maak je tuinmachines winterklaar (inclusief haal- en brengservice!)'
```

Use provided body copy as Markdown. Add front matter:

```toml
cta_label = 'Neem contact op'
cta_url = '/contact/?mode=drive'
```

**Step 2: Render CTA**

Update the generic page CTA handling to support `cta_label` and `cta_url`.

**Step 3: Run checks and commit**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

```bash
git add content/driveshop/winteronderhoud-van-tuinmachines.md layouts/_default/single.html assets/css/style.css
git commit -m "feat: update winter maintenance page"
```

### Task 11: Final Cleanup And Verification

**Files:**
- Modify: `.gitignore`
- Modify: `assets/css/style.css`
- Delete if unused: `layouts/partials/merken-gallery.html`
- Delete if unused: `layouts/partials/merken-gallery-script.html`

**Step 1: Fix undefined border token**

In `assets/css/style.css`, restore:

```css
--border: #d8cfbf;
```

**Step 2: Ignore local repro output**

Add to `.gitignore`:

```gitignore
.tmp-repro-public/
```

**Step 3: Delete dead gallery partials**

Only delete if `rg 'merken-gallery' layouts content data` shows no active callers beyond the partial files and tests.

**Step 4: Final build**

```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:

```text
All site verification checks passed.
```

**Step 5: Review generated pages manually**

Open at least:

- `.test-public/index.html`
- `.test-public/contact/index.html`
- `.test-public/over-ons/index.html`
- `.test-public/bikeshop/merken-en-verdelers/index.html`
- `.test-public/driveshop/merken-en-verdelers/index.html`

Check desktop and mobile widths.

**Step 6: Commit**

```bash
git add .gitignore assets/css/style.css layouts/partials tests/verify_site.ps1
git commit -m "chore: clean up feedback redesign leftovers"
```


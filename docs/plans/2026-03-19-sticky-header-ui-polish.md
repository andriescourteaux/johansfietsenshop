# Sticky Header UI Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Polish the current feature branch so the header, opening-hours rendering, collection hovers, and contact page visuals match the approved UX feedback without regressing performance or mode behavior.

**Architecture:** Keep the existing Hugo partial structure and mode-aware helpers, but centralize the polish in four places: header behavior, opening-hours rendering, shared card motion, and contact styling. The plan deliberately avoids new content models or broader refactors; it tightens the current templates, CSS, verifier hooks, and mode script instead.

**Tech Stack:** Hugo templates, Hugo data/front matter, local CSS, light client-side JavaScript in `mode-script.html`, PowerShell verifier, git worktree workflow.

---

### Task 1: Lock the verifier onto the approved polish behavior

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Add the failing checks for the new header and footer behavior**

Update the verifier so it checks:
- the logo does not rely on overlay opacity changes
- `Contact` is the last visible link in both bike and drive menu lists
- the footer still contains the raw authored `opening_hours` lines with `|`
- the table still renders split hour slots without raw `|`
- sticky/scrolled header hooks exist
- homecards have no border rule
- filter buttons use uppercase, not `small-caps`
- collection cards expose the same hover-motion hooks as homecards
- contact accent hooks and form borders are present

**Step 2: Run the verifier to confirm it fails first**

Run:
```powershell
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: FAIL with the newly added sticky/header/footer/contact/card-polish assertions.

**Step 3: Commit the failing-test change**

```powershell
git add tests/verify_site.ps1
git commit -m "test: cover sticky header ui polish"
```

### Task 2: Fix the header polish and sticky behavior

**Files:**
- Modify: `layouts/partials/header.html`
- Modify: `layouts/partials/site-mode.html`
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Move `Contact` to the end of both mode menus**

In `layouts/partials/site-mode.html`, reorder the menu arrays so the bike menu becomes:
```gohtml
{{- $bikeMenuItems := slice
  (dict "key" "brands" "title" "Merken en verdelers" "href" $bikeBrandsHref)
  (dict "key" "accessoires" "title" "Accessoires" "href" $bikeAccessoriesHref)
  (dict "key" "models" "title" "Enkele modellen in de kijker" "href" $bikeModelsHref)
  (dict "key" "leasing" "title" "Leasing fietsen" "href" $bikeLeasingHref)
  (dict "key" "contact" "title" "Contact" "href" $bikeContactHref)
-}}
```

and the drive menu becomes:
```gohtml
{{- $driveMenuItems := slice
  (dict "key" "brands" "title" "Merken en verdelers" "href" $driveBrandsHref)
  (dict "key" "models" "title" "Modellen in de kijker" "href" $driveModelsHref)
  (dict "key" "winter" "title" "Winteronderhoud van tuinmachines" "href" $driveWinterHref)
  (dict "key" "contact" "title" "Contact" "href" $driveContactHref)
-}}
```

**Step 2: Make the header sticky and preserve two editable gradient states**

In `assets/css/style.css`:
- introduce two CSS variables for the overlay gradients, for example `--header-overlay-gradient-default` and `--header-overlay-gradient-scrolled`
- keep the default value equal to the current gradient
- set the scrolled value to the same gradient family with a less transparent first stop
- make `.site-header` sticky with `top: 0` and a high `z-index`
- remove the logo opacity fade by ensuring `.site-brand`, `.site-brand:hover`, and `.site-brand__logo` stay fully opaque

Example direction:
```css
:root {
    --header-overlay-gradient-default: linear-gradient(180deg, rgba(255, 255, 255, 0.75) 25%, rgba(14, 22, 20, 0) 100%);
    --header-overlay-gradient-scrolled: linear-gradient(180deg, rgba(255, 255, 255, 0.9) 25%, rgba(14, 22, 20, 0.08) 100%);
}

.site-header {
    position: sticky;
    top: 0;
    z-index: 40;
}

.site-header--overlay {
    background: var(--header-overlay-gradient-default);
}

body.site-header-scrolled .site-header--overlay {
    background: var(--header-overlay-gradient-scrolled);
}
```

**Step 3: Add the light scroll-state toggle in the mode script**

In `layouts/partials/mode-script.html`, add a small scroll handler that toggles a class such as `site-header-scrolled` on `body` once the page scrolls a few pixels. Keep it lightweight and compatible with the existing reduced-motion and parallax logic.

**Step 4: Run build plus verifier**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: header-related assertions pass; later footer/card/contact assertions may still fail.

**Step 5: Commit**

```powershell
git add layouts/partials/header.html layouts/partials/site-mode.html layouts/partials/mode-script.html assets/css/style.css
git commit -m "feat: polish sticky header behavior"
```

### Task 3: Split home-table hours but keep raw footer hours

**Files:**
- Modify: `layouts/index.html`
- Modify: `layouts/partials/footer.html`
- Modify: `layouts/partials/opening-hours-data.html`

**Step 1: Keep the table split rendering exactly as-is**

Do not remove the shared split logic in `layouts/partials/opening-hours-data.html`. The table in `layouts/index.html` should continue to render:
```gohtml
{{ range .slots }}
<span class="opening-hours-slot">{{ . }}</span>
{{ end }}
```

**Step 2: Restore raw authored hours in the footer**

In `layouts/partials/footer.html`, stop using the split partial and render the footer directly from `site.Home.Params.opening_hours`, for example:
```gohtml
{{ with $home.Params.opening_hours }}
    {{ range . }}
    <p class="site-footer__hours-line">{{ . }}</p>
    {{ end }}
{{ end }}
```

This intentionally preserves the `|` in the footer text.

**Step 3: Run build plus verifier**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: table and footer opening-hours assertions pass.

**Step 4: Commit**

```powershell
git add layouts/index.html layouts/partials/footer.html layouts/partials/opening-hours-data.html
git commit -m "feat: separate footer and table opening hours"
```

### Task 4: Align collection-card motion, filters, and homecard borders

**Files:**
- Modify: `layouts/partials/media-collection.html`
- Modify: `assets/css/style.css`

**Step 1: Reuse the homecard hover motion on the collection cards**

In `assets/css/style.css`, add the same hover treatment to `.media-collection__card` and its descendants that `.overview-card` already uses:
```css
@media (hover: hover) and (prefers-reduced-motion: no-preference) {
    .media-collection__card:hover,
    .media-collection__card:focus-visible {
        transform: translateY(-0.2rem);
        box-shadow: 0 1rem 2.1rem rgba(16, 16, 16, 0.18);
    }

    .media-collection__card:hover .media-collection__image,
    .media-collection__card:focus-visible .media-collection__image {
        transform: scale(1.03);
    }

    .media-collection__card:hover .media-collection__overlay,
    .media-collection__card:focus-visible .media-collection__overlay {
        opacity: 0.92;
    }
}
```

If needed, add a shared class or selector in `layouts/partials/media-collection.html` so both linked and static cards participate consistently.

**Step 2: Convert filter styling to uppercase**

In `assets/css/style.css`, remove `font-variant: small-caps;` from `.media-collection__filter` and use uppercase styling instead:
```css
.media-collection__filter {
    text-transform: uppercase;
    letter-spacing: 0.08em;
    font-variant: normal;
}
```

**Step 3: Remove the homecard border**

In `assets/css/style.css`, remove the explicit border from `.overview-card` while keeping the shadow and hover motion.

**Step 4: Run build plus verifier**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: homecard border, filter, and collection-hover checks pass.

**Step 5: Commit**

```powershell
git add layouts/partials/media-collection.html assets/css/style.css
git commit -m "feat: align card hover motion and filter styling"
```

### Task 5: Fix contact accent colors and field visibility

**Files:**
- Modify: `layouts/_default/single.html`
- Modify: `assets/css/style.css`

**Step 1: Make the accent variable truly mode-aware**

In `assets/css/style.css`, update the mode-scoped `body[data-site-mode="bike"]` and `body[data-site-mode="drive"]` blocks to assign a real `--accent` value:
```css
body[data-site-mode="bike"],
body[data-theme="bike"] {
    --accent: #ffc100;
}

body[data-site-mode="drive"],
body[data-theme="drive"] {
    --accent: #b93f33;
}
```

This should automatically recolor `Johan Alliet`, the contact labels, focus borders, and notice/button accents.

**Step 2: Make the form fields visibly framed again**

Strengthen the field borders and contrast in `assets/css/style.css`:
```css
.contact-form,
.contact-form input,
.contact-form textarea {
    border: 1px solid rgba(31, 28, 24, 0.18);
}
```

Keep the layout and map embed unchanged.

**Step 3: Verify the contact markup still exposes the accent hooks**

Ensure `layouts/_default/single.html` still includes:
- `contact-panel__name`
- `contact-panel__term`
- `contact-panel__map`

**Step 4: Run build plus verifier**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
hugo
```

Expected: all checks pass.

**Step 5: Commit**

```powershell
git add layouts/_default/single.html assets/css/style.css
git commit -m "feat: fix contact accent and form visibility"
```

### Task 6: Final review and completion

**Files:**
- Review: `layouts/partials/header.html`
- Review: `layouts/partials/footer.html`
- Review: `layouts/index.html`
- Review: `layouts/partials/media-collection.html`
- Review: `layouts/_default/single.html`
- Review: `assets/css/style.css`
- Review: `tests/verify_site.ps1`

**Step 1: Inspect the final diff**

Run:
```powershell
git diff --stat HEAD~4..HEAD
git status
```

Expected: only the intended polish commits and a clean worktree.

**Step 2: Perform manual browser checks**

Check:
- logo remains fully opaque in all states
- `Contact` is last in both menus
- sticky header stays pinned while the hero scrolls behind it
- scrolled gradient is visibly but only slightly stronger than the default one
- footer keeps pipe text
- home table splits midday slots over multiple lines
- collection cards hover like homecards
- filter tags are uppercase
- homecards have no border
- contact page is yellow in bike and red in drive

**Step 3: Summarize and hand off**

Report the final commit chain, verification commands, and any remaining visual follow-up that is intentionally left adjustable, especially the two header gradient values.

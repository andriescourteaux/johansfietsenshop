# Hero, Menu, Openingsuren En Contactkaart Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update the shared hero, header menu, opening-hours rendering, and contact page styling so the site reads cleaner and the contact page includes a map embed.

**Architecture:** Keep the existing Hugo mode-aware structure and patch the shared partials instead of introducing a new content model. Use the existing PowerShell verifier for hook-level regression checks, keep the opening-hours source in `content/_index.md`, and centralize the visual behavior in `style.css` plus the existing `mode-script.html`.

**Tech Stack:** Hugo templates, front matter content, vanilla JS, local CSS, PowerShell verifier.

---

### Task 1: Extend The Verifier For Hero, Menu, Hours, And Contact Hooks

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Write the failing test**

Add assertions for:
- `layouts/partials/shared-hero.html` no longer rendering the `Site2` eyebrow marker
- `layouts/partials/header.html` no longer rendering the visible `.site-nav__contact` link
- generated header menu output containing `Contact` in both bike and drive menu lists
- menu-opening hooks existing in `layouts/partials/mode-script.html` and `assets/css/style.css`
- rendered home opening-hours markup splitting `|` into multiple child lines instead of showing the raw pipe
- rendered contact markup containing dedicated accentable label/name hooks and a Google Maps iframe

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- `hugo --destination .test-public` passes
- verifier fails on the new hero/menu/hours/contact expectations

**Step 3: Commit**

```powershell
git add tests/verify_site.ps1
git commit -m "test: add hero menu hours contact checks"
```

### Task 2: Remove The Hero Eyebrow And Keep The Home Copy On One Desktop Line

**Files:**
- Modify: `layouts/partials/shared-hero.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the red verifier from Task 1 as the failing test for the missing hero cleanup hooks.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier reports the eyebrow removal and/or hero copy layout hooks as missing

**Step 3: Write minimal implementation**

In `layouts/partials/shared-hero.html`:
- remove the `Site2` eyebrow paragraph

In `assets/css/style.css`:
- widen or relax the hero copy container on desktop
- apply `white-space: nowrap` to the home hero intro copy on larger breakpoints only
- restore normal wrapping on narrower breakpoints so mobile remains safe

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- hero-related failures disappear
- later menu/contact/hour failures may remain

**Step 5: Commit**

```powershell
git add layouts/partials/shared-hero.html assets/css/style.css
git commit -m "feat: refine hero heading layout"
```

### Task 3: Move Contact Into The Menu And Fix Menu Open Animation

**Files:**
- Modify: `layouts/partials/header.html`
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the remaining verifier failures for the header/menu hooks as the failing test.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier reports visible contact-link or menu-opening hook failures

**Step 3: Write minimal implementation**

In `layouts/partials/header.html`:
- remove the visible `.site-nav__contact` anchor
- add `Contact` as the first menu link inside both bike and drive menu lists

In `layouts/partials/mode-script.html`:
- keep `hidden` as the real closed state
- change the opening flow so the menu is first unhidden in a closed visual state, then promoted to `opening`/`open`
- keep the existing mode sync intact

In `assets/css/style.css`:
- ensure the open state has its own transition path from the closed state
- keep the close animation behavior intact

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- menu-related failures disappear
- hours/contact failures may remain

**Step 5: Commit**

```powershell
git add layouts/partials/header.html layouts/partials/mode-script.html assets/css/style.css
git commit -m "feat: move contact into the header menu"
```

### Task 4: Split Opening Hours Pipes Into Multiple Rendered Lines

**Files:**
- Modify: `layouts/index.html`
- Modify: `layouts/partials/footer.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the remaining verifier failures for opening-hours rendering as the failing test.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier reports raw pipe characters or missing multi-line hours markup

**Step 3: Write minimal implementation**

In `layouts/index.html`:
- split each day-hours string on `|`
- render each time slot as its own child element inside the same table cell
- avoid printing the raw pipe character

In `layouts/partials/footer.html`:
- apply the same split to the footer hours output
- keep the overall footer presentation sober

In `assets/css/style.css`:
- style the table cell slots and footer slots as stacked lines with small gaps

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- hours-related failures disappear
- contact/map failures may remain

**Step 5: Commit**

```powershell
git add layouts/index.html layouts/partials/footer.html assets/css/style.css
git commit -m "feat: render split opening hours"
```

### Task 5: Restyle Contact Details And Add The Google Maps Embed

**Files:**
- Modify: `layouts/_default/single.html`
- Modify: `assets/css/style.css`

**Step 1: Write the failing test**

Use the remaining verifier failures for contact accent hooks and map embed as the failing test.

**Step 2: Run test to verify it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier reports missing contact label/name hooks or missing map iframe

**Step 3: Write minimal implementation**

In `layouts/_default/single.html`:
- convert the hardcoded contact rows into explicit label/value markup
- wrap `Johan Alliet` in its own accentable element
- add a map block under the detail/form row using a standard Google Maps iframe for `Kalve 62, 9185 Wachtebeke`

In `assets/css/style.css`:
- bind the contact label/name accent color to the active bike/drive theme variables
- keep the values readable in the normal text color
- add a stable responsive layout for the map block

**Step 4: Run test to verify it passes**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier passes the new contact/map checks

**Step 5: Commit**

```powershell
git add layouts/_default/single.html assets/css/style.css
git commit -m "feat: enrich the contact page"
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
- hero shows no `Site2`
- home intro stays on one line on desktop and wraps safely on mobile
- `Contact` is no longer visible in the top header row
- `Contact` appears in both bike and drive menu variants
- menu open and close animations both work
- opening-hours rows split midday pauses onto separate lines
- footer hours follow the same split
- `Johan Alliet` and contact labels pick up the bike/drive accent color
- Google Maps iframe renders correctly on contact

**Step 4: Commit**

```powershell
git add tests/verify_site.ps1 layouts/partials/shared-hero.html layouts/partials/header.html layouts/partials/mode-script.html layouts/index.html layouts/partials/footer.html layouts/_default/single.html assets/css/style.css
git commit -m "feat: polish hero menu hours and contact page"
```

# Header Menu Consistency Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the shared header so the hamburger menu is correctly filtered per mode, opens directly under the toggle, and uses the same stable navigation styling on homepage and single pages.

**Architecture:** Keep one shared header partial and one mode-sync script. Fix the mode filtering at the CSS and JavaScript layers, move dropdown anchoring into the local nav shell, and centralize navigation typography and spacing in the shared base header styles rather than the homepage overlay variant.

**Tech Stack:** Hugo templates, Hugo partials, vanilla JavaScript, site CSS, PowerShell verification script.

---

### Task 1: Extend verification for header consistency

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Write the failing verification changes**

Update the verifier so it checks for:
- a local menu anchor shell in the header markup
- a CSS rule that respects hidden mode lists
- shared nav typography markers that appear outside overlay-only selectors
- output markers confirming only one mode list is active per page type, if represented in markup/class naming

**Step 2: Run verification to confirm it fails**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- Hugo build succeeds
- verifier fails with missing markers for the new header-shell and consistency rules

**Step 3: Commit the verification change**

```powershell
git add tests/verify_site.ps1
git commit -m "test: verify header menu consistency"
```

### Task 2: Fix header markup anchoring

**Files:**
- Modify: `layouts/partials/header.html`

**Step 1: Update the shared header structure**

Refactor the nav markup so:
- the menu toggle and dropdown share a dedicated local wrapper, for example `site-nav__menu-shell`
- the dropdown stays in the nav component instead of the wider header container
- bike and drive lists remain separate and mode-aware

**Step 2: Rebuild the site**

Run:
```powershell
hugo --destination .test-public
```

Expected:
- build succeeds
- generated pages contain the new local menu-shell marker

**Step 3: Commit the markup change**

```powershell
git add layouts/partials/header.html
git commit -m "feat: anchor header dropdown to toggle"
```

### Task 3: Fix mode filtering behavior

**Files:**
- Modify: `layouts/partials/mode-script.html`
- Modify: `assets/css/style.css`

**Step 1: Make visibility robust in CSS**

Add rules that explicitly keep inactive mode lists hidden, for example:
- `.site-nav__menu-list[hidden] { display: none !important; }`

Keep the active list layout styling separate so `hidden` is never accidentally overridden.

**Step 2: Tighten menu syncing in JavaScript**

Update the mode-sync logic so it:
- toggles the correct list on load
- keeps hidden state aligned with the active mode
- optionally updates `aria-hidden`
- closes the dropdown cleanly if a mode switch changes visible content while it is open

**Step 3: Run verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier no longer reports mixed mode-menu visibility issues

**Step 4: Commit the filtering fix**

```powershell
git add layouts/partials/mode-script.html assets/css/style.css
git commit -m "fix: filter header menu by active mode"
```

### Task 4: Normalize nav typography and spacing

**Files:**
- Modify: `assets/css/style.css`

**Step 1: Move shared nav typography into base header selectors**

Refactor the CSS so the following share the same typography foundation on home and singles:
- `.site-brand`
- `.site-nav__item`
- `.site-nav__switch`
- `.site-nav__menu-toggle`
- `.site-nav__menu-link`

Use stable rem-based sizing instead of viewport-height sizing for the navigation.

**Step 2: Reduce overlay rules to visual contrast only**

Keep overlay-specific rules limited to:
- color
- opacity
- hover contrast

Remove overlay-only font family, font variant, and spacing differences that currently make homepage nav look different.

**Step 3: Normalize header height**

Adjust `.site-header__inner` and the overlay variant so the vertical rhythm remains visually stable and no small upward/downward shift appears between home and single pages.

**Step 4: Re-run build and verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected:
- verifier passes all header-related checks

**Step 5: Commit the styling fix**

```powershell
git add assets/css/style.css
git commit -m "style: unify header navigation styling"
```

### Task 5: Final verification and review

**Files:**
- Review: `layouts/partials/header.html`
- Review: `layouts/partials/mode-script.html`
- Review: `assets/css/style.css`
- Review: `tests/verify_site.ps1`

**Step 1: Run full verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
hugo
```

Expected:
- all commands exit 0
- verifier prints `All site verification checks passed.`

**Step 2: Perform manual browser checks**

Run:
```powershell
hugo server
```

Verify manually:
- home in bike mode shows only bike menu items
- home in drive mode shows only drive menu items
- a single page in bike mode still shows only bike menu items
- a single page in drive mode still shows only drive menu items
- the dropdown opens directly beneath the hamburger toggle
- home and single-page nav typography match
- there is no visible header jump between page types

**Step 3: Review the final diff**

Run:
```powershell
git diff --stat HEAD~4 HEAD
git status --short
```

Expected:
- only intended header/menu consistency files are part of the feature
- unrelated user files remain untouched

**Step 4: Commit any last verifier or CSS adjustments**

If needed:
```powershell
git add layouts/partials/header.html layouts/partials/mode-script.html assets/css/style.css tests/verify_site.ps1
git commit -m "chore: finalize header consistency fix"
```

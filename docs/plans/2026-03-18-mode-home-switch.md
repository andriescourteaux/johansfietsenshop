# Mode Home Switch Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change the visible bike/drive navigation so the header switch and homepage overview cards link to homepage mode URLs instead of the standalone `/bikeshop/` and `/driveshop/` pages.

**Architecture:** Reuse the existing mode-aware helper and shared-page persistence logic. Only the switch hrefs and the homepage overview card hrefs change; the standalone bike and drive pages remain in the site but are removed from the normal navigation flow.

**Tech Stack:** Hugo, Go template partials, CSS, PowerShell verification script

---

### Task 1: Extend verification for homepage-mode navigation

**Files:**
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`
- Test: `K:\Coding\Site2\.test-public\index.html`
- Test: `K:\Coding\Site2\.test-public\bikeshop\index.html`
- Test: `K:\Coding\Site2\.test-public\driveshop\index.html`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it expects:

- bike-mode header switch to include `/?mode=drive`
- drive-mode header switch to include `/?mode=bike`
- homepage `Bikeshop` overview card to include `/?mode=bike`
- homepage `Driveshop` overview card to include `/?mode=drive`
- the normal header switch and homepage overview cards to no longer use `/bikeshop/` or `/driveshop/` as destinations

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current helper and homepage overview still point at the standalone shop pages.

**Step 3: Write minimal implementation**

Only update the verification harness. Do not change templates yet.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL with missing homepage-mode navigation markers.

**Step 5: Commit**

```bash
git add tests/verify_site.ps1
git commit -m "test: verify homepage mode navigation"
```

### Task 2: Update the header switch and home overview links

**Files:**
- Modify: `K:\Coding\Site2\layouts\partials\site-mode.html`
- Modify: `K:\Coding\Site2\layouts\index.html`
- Modify: `K:\Coding\Site2\layouts\partials\mode-script.html`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Use the Task 1 verification already written and target these conditions:

- the header switch href resolves to homepage mode URLs
- the homepage Bike and Drive overview cards resolve to homepage mode URLs
- the overview cards no longer point directly to `/bikeshop/` or `/driveshop/`

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL because the current templates still use the standalone shop routes in normal navigation.

**Step 3: Write minimal implementation**

Update:

- `switchBikeHref` to `/?mode=drive`
- `switchDriveHref` to `/?mode=bike`
- homepage `Bikeshop` overview card href to `/?mode=bike`
- homepage `Driveshop` overview card href to `/?mode=drive`

Keep all other mode-aware logic unchanged.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS.

Also run:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add layouts/partials/site-mode.html layouts/index.html layouts/partials/mode-script.html tests/verify_site.ps1
git commit -m "feat: route shop navigation through homepage modes"
```

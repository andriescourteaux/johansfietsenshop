# Bike Homecard Images Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update the four bikeshop homepage cards to use the new dedicated images from `static/images/home-cards/` while leaving driveshop cards unchanged.

**Architecture:** Modify the existing `bikePanels` image mapping in `layouts/partials/site-mode.html` only. No structural template or CSS changes are needed because the homepage card system already supports per-card image paths.

**Tech Stack:** Hugo templates, static assets, PowerShell verification commands.

---

### Task 1: Update the bikeshop homecard image mapping

**Files:**
- Modify: `layouts/partials/site-mode.html`

**Step 1: Change only the four bike panel image paths**

Set the following mappings:
- `brands` -> `/images/home-cards/bike-merken.jpg`
- `accessoires` -> `/images/home-cards/bike-accessoires.webp`
- `models` -> `/images/home-cards/bike-modellen.jpg`
- `leasing` -> `/images/home-cards/bike-lease.jpg`

Leave all driveshop panel image paths as they are.

**Step 2: Run build verification**

Run:
```powershell
hugo --destination .test-public
```

Expected:
- build succeeds

**Step 3: Confirm the generated homepage references the new images**

Run:
```powershell
Select-String -Path .test-public/index.html -Pattern 'bike-merken.jpg|bike-accessoires.webp|bike-modellen.jpg|bike-lease.jpg'
```

Expected:
- all four image names appear in the generated homepage output

**Step 4: Final build check**

Run:
```powershell
hugo
```

Expected:
- build succeeds

**Step 5: Commit**

```powershell
git add layouts/partials/site-mode.html
git commit -m "feat: update bikeshop homecard images"
```

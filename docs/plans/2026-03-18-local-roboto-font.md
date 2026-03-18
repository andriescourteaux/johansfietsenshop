# Local Roboto Font Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Configureer de site om Roboto lokaal te hosten en gebruik geen serif fonts meer in de hoofdtypografie.

**Architecture:** De wijziging blijft binnen de bestaande stylesheet en verificatieflow. Self-hosted `@font-face`-regels in `assets/css/style.css` verwijzen naar de reeds aanwezige `static/fonts/Roboto-*.ttf` bestanden, terwijl het verificatiescript deze markers valideert.

**Tech Stack:** Hugo, CSS, PowerShell verification script

---

### Task 1: Breid verificatie uit voor self-hosted Roboto

**Files:**
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`
- Test: `K:\Coding\Site2\assets\css\style.css`

**Step 1: Write the failing test**

Voeg CSS-checks toe die verwachten:
- `@font-face` voor `Roboto`
- lokale font-URLs voor `Roboto-Regular.ttf` en `Roboto-Bold.ttf`
- een body-stack met `"Roboto", Arial, sans-serif`

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL omdat de stylesheet nog geen self-hosted Roboto-definities bevat.

**Step 3: Write minimal implementation**

Werk alleen het verificatiescript bij. Pas de stylesheet nog niet aan.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL met missende Roboto-markers in de CSS.

### Task 2: Voeg self-hosted Roboto toe aan de stylesheet

**Files:**
- Modify: `K:\Coding\Site2\assets\css\style.css`
- Test: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Gebruik de verificatie uit Task 1 als rode basis.

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: FAIL omdat de CSS nog niet lokaal naar Roboto verwijst.

**Step 3: Write minimal implementation**

Voeg in `assets/css/style.css` toe:
- `@font-face` voor regular, italic, bold en bold italic
- `font-display: swap`
- `body { font-family: "Roboto", Arial, sans-serif; }`
- verwijder de overgebleven serif-rest in de body stack

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\style.css -HeadTemplatePath layouts\partials\head.html`

Expected: PASS.

Also run: `hugo`

Expected: exit code 0.

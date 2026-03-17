# Hugo Site Base Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a new Dutch Hugo website base with a full-screen homepage hero, an overlaid homepage header, and four interior pages: Contact, Merken en verdelers, Driveshop, and Bikeshop.

**Architecture:** Create the site directly in the empty workspace using Hugo content files, one shared layout for interior pages, and a dedicated homepage layout. Keep shared structure in partials, keep all visual styling in one stylesheet, store the placeholder banner under `static/`, and verify the generated HTML with a small PowerShell regression script after each feature step.

**Tech Stack:** Hugo, Go template layouts, Markdown content files, CSS, PowerShell verification script

---

### Task 1: Scaffold the Hugo site and create the verification harness

**Files:**
- Create: `K:\Coding\Site2\hugo.toml`
- Create: `K:\Coding\Site2\archetypes\default.md`
- Create: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Create `tests\verify_site.ps1` with checks for these files inside a built output directory:

- `index.html`
- `contact\index.html`
- `merken-en-verdelers\index.html`
- `driveshop\index.html`
- `bikeshop\index.html`

The script should exit non-zero when any file is missing.

**Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: FAIL because no Hugo site or built output exists yet.

**Step 3: Write minimal implementation**

Create:

- `hugo.toml` with Dutch site metadata and clean URLs
- `archetypes\default.md` with a simple front matter template
- the initial `tests\verify_site.ps1` script that accepts `-PublicDir`

Do not add page content yet.

**Step 4: Run test to verify it still fails for the expected reason**

Run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: FAIL because the required built HTML files still do not exist.

**Step 5: Commit**

```bash
git add hugo.toml archetypes/default.md tests/verify_site.ps1
git commit -m "chore: scaffold Hugo site config and verification script"
```

If `git` has not been initialized in this workspace yet, initialize it before the first commit.

### Task 2: Add site content, shared layout, and global navigation

**Files:**
- Create: `K:\Coding\Site2\content\_index.md`
- Create: `K:\Coding\Site2\content\contact.md`
- Create: `K:\Coding\Site2\content\merken-en-verdelers.md`
- Create: `K:\Coding\Site2\content\driveshop.md`
- Create: `K:\Coding\Site2\content\bikeshop.md`
- Create: `K:\Coding\Site2\layouts\_default\baseof.html`
- Create: `K:\Coding\Site2\layouts\_default\single.html`
- Create: `K:\Coding\Site2\layouts\partials\head.html`
- Create: `K:\Coding\Site2\layouts\partials\header.html`
- Create: `K:\Coding\Site2\layouts\partials\footer.html`
- Create: `K:\Coding\Site2\assets\css\site.css`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it also asserts:

- every expected page file exists after build
- every page contains navigation links for `Contact`, `Bikeshop`, `Driveshop`, and `Merken en verdelers`
- every interior page contains its page title in the HTML

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: FAIL because the content files and templates are not present yet.

**Step 3: Write minimal implementation**

Create:

- Markdown content files for the homepage and four interior pages
- a `baseof.html` template with shared page shell
- a `single.html` template for the interior pages
- partials for head, header, and footer
- a first-pass stylesheet for body, container, navigation, and footer layout

Use Dutch titles and introductory copy.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: PASS for file existence, page titles, and shared navigation.

**Step 5: Commit**

```bash
git add content layouts assets/css/site.css tests/verify_site.ps1
git commit -m "feat: add Hugo content pages and shared site layout"
```

### Task 3: Build the homepage hero with overlaid header and placeholder banner

**Files:**
- Create: `K:\Coding\Site2\layouts\index.html`
- Create: `K:\Coding\Site2\static\images\hero-placeholder.svg`
- Modify: `K:\Coding\Site2\assets\css\site.css`
- Modify: `K:\Coding\Site2\layouts\partials\header.html`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so the homepage assertions require:

- a hero wrapper element
- a reference to `/images/hero-placeholder.svg`
- header markup rendered inside or over the hero region
- homepage intro text present in the hero

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: FAIL because the homepage still uses the shared layout and has no hero-specific structure.

**Step 3: Write minimal implementation**

Create:

- `layouts\index.html` with a full-viewport hero
- a placeholder SVG banner asset
- hero-specific CSS for image treatment, overlay, text, and header positioning
- conditional header markup or classes needed for homepage overlay behavior

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: PASS for homepage hero markup and placeholder banner reference.

**Step 5: Commit**

```bash
git add layouts/index.html layouts/partials/header.html static/images/hero-placeholder.svg assets/css/site.css tests/verify_site.ps1
git commit -m "feat: add full-screen homepage hero"
```

### Task 4: Add the contact page placeholder form

**Files:**
- Modify: `K:\Coding\Site2\content\contact.md`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Modify: `K:\Coding\Site2\assets\css\site.css`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so the contact page must include:

- a `<form>` element
- inputs for name, email, and subject
- a textarea for message
- placeholder notice text stating that online sending is not active yet

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: FAIL because the contact page does not yet render a form.

**Step 3: Write minimal implementation**

Add:

- contact-specific front matter or content markers if needed
- conditional form rendering in `single.html`
- form styling in `site.css`

Keep the submit action inert and clearly present the placeholder notice.

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: PASS for all contact form fields and placeholder notice.

**Step 5: Commit**

```bash
git add content/contact.md layouts/_default/single.html assets/css/site.css tests/verify_site.ps1
git commit -m "feat: add placeholder contact form"
```

### Task 5: Add section-specific content blocks for the shop and dealer pages

**Files:**
- Modify: `K:\Coding\Site2\content\driveshop.md`
- Modify: `K:\Coding\Site2\content\bikeshop.md`
- Modify: `K:\Coding\Site2\content\merken-en-verdelers.md`
- Modify: `K:\Coding\Site2\layouts\_default\single.html`
- Modify: `K:\Coding\Site2\assets\css\site.css`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it also asserts:

- `driveshop/index.html` contains at least one highlight section and a contact-oriented call to action
- `bikeshop/index.html` contains at least one highlight section and a contact-oriented call to action
- `merken-en-verdelers/index.html` contains placeholder blocks for both brands and dealers

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: FAIL because the interior pages still contain only generic content.

**Step 3: Write minimal implementation**

Add:

- structured front matter or content sections for highlights and placeholders
- shared template rendering for highlight cards and CTA blocks
- restrained CSS for cards, lists, and section spacing

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public`

Expected: PASS for shop highlights, CTA content, and the brands/dealers placeholders.

**Step 5: Commit**

```bash
git add content/driveshop.md content/bikeshop.md content/merken-en-verdelers.md layouts/_default/single.html assets/css/site.css tests/verify_site.ps1
git commit -m "feat: add page-specific content sections"
```

### Task 6: Add responsive polish and run final verification

**Files:**
- Modify: `K:\Coding\Site2\assets\css\site.css`
- Modify: `K:\Coding\Site2\tests\verify_site.ps1`

**Step 1: Write the failing test**

Extend `tests\verify_site.ps1` so it checks:

- `assets\css\site.css` contains a mobile breakpoint
- the homepage HTML still includes hero and navigation structure
- all expected routes are still generated in the final build

**Step 2: Run test to verify it fails**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\site.css`

Expected: FAIL because the mobile breakpoint or final assertions are not fully present yet.

**Step 3: Write minimal implementation**

Add:

- mobile layout rules for hero text, navigation, card grids, and form layout
- any final spacing or typography cleanup needed to keep the site sober and readable

**Step 4: Run test to verify it passes**

Run: `hugo --destination .test-public`

Then run: `powershell -ExecutionPolicy Bypass -File tests\verify_site.ps1 -PublicDir .test-public -CssPath assets\css\site.css`

Expected: PASS for the final build and responsive CSS assertions.

Also run a clean production build:

Run: `hugo`

Expected: exit code 0 with no build errors.

**Step 5: Commit**

```bash
git add assets/css/site.css tests/verify_site.ps1
git commit -m "feat: finalize responsive Hugo site base"
```

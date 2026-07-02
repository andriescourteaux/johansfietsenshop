# Footer Contact Column Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a centered footer contact column that shares address, e-mail, phone, and name data with the contact page.

**Architecture:** Move the core contact fields into a single Hugo data file and let both the footer partial and the contact page template render from that same source. Extend the stylesheet for a three-column footer layout while keeping the rest of the footer behavior intact.

**Tech Stack:** Hugo templates, Hugo data files, local CSS, PowerShell verifier, git workflow.

---

### Task 1: Lock the verifier onto the shared contact source first

**Files:**
- Modify: `tests/verify_site.ps1`

**Step 1: Add failing checks for the new footer contact column**

Update the verifier so it checks:
- `data/contact.toml` exists
- the data file exposes `name`, `address`, `email`, and `phone`
- the generated footer contains a dedicated contact column
- the footer renders `Adres`, `E-mail`, and `Telefoon` in that order
- the generated contact page contains the same shared values

**Step 2: Run the verifier to confirm it fails first**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
```

Expected: FAIL because the shared data file and the new footer contact column do not exist yet.

### Task 2: Add the shared contact data source

**Files:**
- Create: `data/contact.toml`

**Step 1: Add the shared contact fields**

Create `data/contact.toml` with:

```toml
name = "Johan Alliet"
address = "Kalve 62, 9185 Wachtebeke"
email = "johan.alliet@telenet.be"
phone = "0472/93 03 56"
```

**Step 2: Re-run the verifier**

Run the same verifier command. Expected: data-file checks pass, footer/contact rendering checks still fail.

### Task 3: Render the footer from the shared contact source

**Files:**
- Modify: `layouts/partials/footer.html`

**Step 1: Add a middle footer contact column**

Render a new contact block between the hours and the links columns using `.Site.Data.contact` and this order:
- `Adres`
- `E-mail`
- `Telefoon`

**Step 2: Preserve the existing hours and navigation links**

Do not remove the opening-hours column or the existing right-side links.

**Step 3: Re-run the verifier**

Expected: footer checks pass, contact-page shared-data checks may still fail.

### Task 4: Make the contact page reuse the shared data

**Files:**
- Modify: `layouts/_default/single.html`

**Step 1: Replace the duplicated name/address/e-mail/phone values**

Use `.Site.Data.contact` for:
- `Johan Alliet`
- address
- e-mail
- phone

Keep the extra page-only items such as VAT and payment methods where they are.

**Step 2: Re-run the verifier**

Expected: footer and contact shared-data checks pass.

### Task 5: Extend the footer styling for the new middle column

**Files:**
- Modify: `assets/css/style.css`

**Step 1: Add three-column footer layout rules**

Update the footer layout to support:
- hours column
- contact column
- link column

**Step 2: Add compact contact styles**

Style the new footer contact list so it is readable, scanable, and stacks cleanly on mobile.

**Step 3: Run full verification**

Run:
```powershell
hugo --destination .test-public
powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html
hugo
```

Expected: all commands pass.

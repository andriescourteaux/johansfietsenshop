# Footer Contact Column Design

**Doel**

De footer krijgt een derde, middenste kolom met beknopte contactgegevens. Die contactgegevens moeten uit dezelfde gedeelde bron komen als de contactpagina, zodat adres, e-mail en telefoonnummer maar op ??n plaats beheerd worden.

**Reikwijdte**

- de footer evolueert van 2 naar 3 kolommen
- de middenkolom toont `Adres`, `E-mail`, `Telefoon`
- de volgorde blijft exact die volgorde
- de contactpagina hergebruikt dezelfde gedeelde basiscontactgegevens
- de resterende contact-specifieke info mag op de contactpagina blijven bestaan
- de styling blijft sober en sluit aan op de huidige footer

**Aanpak**

- `data/contact.toml` wordt de gedeelde bron voor `name`, `address`, `email` en `phone`
- `layouts/partials/footer.html` leest die data en rendert de nieuwe middenkolom
- `layouts/_default/single.html` leest dezelfde data voor de kerncontactgegevens op de contactpagina
- `assets/css/style.css` krijgt een 3-koloms footerlayout en compacte contactstijlen
- `tests/verify_site.ps1` wordt uitgebreid zodat footer en contactpagina dezelfde contactbron moeten weerspiegelen

**Footerstructuur**

- linker kolom: openingsuren
- middenkolom: contactgegevens
- rechter kolom: bestaande navigatielinks

De middenkolom blijft sober:

- kleine titel
- compacte labels
- scanbare waardes
- nette stacking op mobiel

**Onderhoud**

Na deze wijziging wordt de onderhoudsflow:

- telefoon, e-mail of adres wijzigen: enkel `data/contact.toml`
- footer en contactpagina volgen automatisch mee
- geen templatewijziging nodig voor gewone contactupdates

**Verificatie**

Na implementatie moet minimaal gecontroleerd worden:

- `data/contact.toml` bestaat en bevat de gedeelde velden
- footer rendert de contactkolom
- footer rendert adres, e-mail en telefoon in die volgorde
- contactpagina rendert dezelfde gedeelde gegevens
- bestaande footerlinks en openingsuren blijven aanwezig

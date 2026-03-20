# Hero, Menu, Openingsuren En Contactkaart Design

## Doel

Werk de home-hero, navigatie, openingsuren en contactpagina bij zodat de site consistenter leest, het menu logischer aanvoelt en contactinformatie sterker uitgewerkt is zonder de sobere stijl te verliezen.

## Goedgekeurde Beslissingen

### Hero
- Verwijder de `Site2` eyebrow uit de gedeelde hero.
- Houd de home-zin onder `Welkom bij Johan's Fietsenshop!` op desktop op één lijn.
- Laat diezelfde zin op smallere schermen opnieuw normaal afbreken.

### Navigatie
- Verwijder `Contact` uit de zichtbare headerregel.
- Toon `Contact` in het openklapmenu in zowel bike- als drive-modus.
- Behoud verder de bestaande logo/toggle/menu-structuur.
- Maak de menu-openanimatie echt tweezijdig: openen én sluiten moeten geanimeerd verlopen.

### Openingsuren
- Laat de bron in `content/_index.md` pipe-gescheiden blijven, bijvoorbeeld `10:00u - 12:00 | 13:00 - 19:00`.
- Render de pipe in de home-tabel als een echte nieuwe regel binnen dezelfde dagcel.
- Verwijder de pipe visueel uit de tabeloutput.
- Pas dezelfde splitsing toe in de footeruren, maar behoud daar de sobere tekstpresentatie.

### Contactpagina
- Accentueer `Johan Alliet` en de labels zoals `Adres:`, `GSM:` en `E-mail:` in vet met de actieve accentkleur.
- Laat de waarden zelf sober in de gewone tekstkleur.
- Voeg een standaard Google Maps embed toe voor `Kalve 62, 9185 Wachtebeke`.
- Gebruik een stabiele layout:
  - desktop: details links, formulier rechts, kaart onderaan over de volle breedte
  - mobiel: alles onder elkaar

## Verwachte Implementatiepunten
- `layouts/partials/shared-hero.html`
- `layouts/partials/header.html`
- `layouts/partials/mode-script.html`
- `layouts/index.html`
- `layouts/partials/footer.html`
- `layouts/_default/single.html`
- `assets/css/style.css`
- `tests/verify_site.ps1`

## Risico's
- De menu-openfix moet de bestaande close-state en `hidden`-semantiek intact laten.
- De hero-copy mag desktop no-wrap krijgen zonder mobiel te breken.
- De opening-hours parsing moet zowel tabel als footer correct blijven voeden vanuit dezelfde bronregel.
- De map embed mag de contactlayout niet instabiel maken op smallere schermen.

## Verificatie
- `hugo --destination .test-public`
- `powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html`
- `hugo`
- Handmatig nalopen:
  - hero zonder `Site2`
  - home-zin op desktop op één lijn
  - `Contact` alleen in het menu en in beide modi zichtbaar
  - menu opent en sluit met animatie
  - openingsuren met `|` worden als meerdere regels weergegeven
  - contactlabels en `Johan Alliet` kleuren mee per modus
  - Google Maps iframe toont correct

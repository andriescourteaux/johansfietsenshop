# Shared Header En Media-Collecties Design

**Goal:** Breid de site uit met herbruikbare mode-specifieke mediacollecties voor leasing, accessoires en modellen in de kijker, voeg een mode-aware hamburgermenu toe aan de gedeelde header, en maak de homepage-kaarten beeldgedreven met overlaytitels.

## Huidige Context

De site gebruikt vandaag al een gedeelde base layout in `layouts/_default/baseof.html`, met een herbruikbare header-partial in `layouts/partials/header.html`, een centrale mode-helper in `layouts/partials/site-mode.html`, en een mode-script in `layouts/partials/mode-script.html`. `Merken en verdelers` gebruikt al een dynamische grid op basis van statische afbeeldingsmappen en TOML-metadata.

De homepage rendert mode-specifieke kaartsets via `layouts/index.html`, maar die kaarten zijn nog tekstblokken zonder kaartafbeeldingen. De single-template in `layouts/_default/single.html` ondersteunt vandaag alleen highlights, contact, CTA's en de merken-gallery-flow.

## Gekozen Aanpak

De gekozen aanpak is om de bestaande merken-gallery te veralgemenen naar een herbruikbare collectie-renderer met presentatievarianten:
- `brand-links` voor logo-gebaseerde grids met optionele externe links
- `hover-cards` voor fotogrids met hover-overlaytitel
- filtering alleen voor `merken en verdelers`

De header blijft exact één gedeelde partial. Die partial krijgt een mode-aware hamburgermenu dat uit dezelfde centrale mode-data leest als de homepage-kaarten. Zo blijven headernavigatie en homeflow consistent zonder dubbele linkdefinities.

## Ontwerpkeuzes

### 1. Aparte Bronnen Per Modus En Per Pagina

Elke collectie krijgt een eigen map per modus en paginatype, zodat inhoud en metadata strikt gescheiden blijven.

Voor bikeshop:
- `static/images/collecties/bikeshop/merken-en-verdelers/`
- `static/images/collecties/bikeshop/leasing-fietsen/`
- `static/images/collecties/bikeshop/accessoires/`
- `static/images/collecties/bikeshop/modellen-in-de-kijker/`

Voor driveshop:
- `static/images/collecties/driveshop/merken-en-verdelers/`
- `static/images/collecties/driveshop/modellen-in-de-kijker/`

Elke collectie krijgt een bijhorende datafile, bijvoorbeeld:
- `data/collecties/bikeshop/leasing-fietsen.toml`
- `data/collecties/bikeshop/accessoires.toml`
- `data/collecties/driveshop/modellen-in-de-kijker.toml`

Deze structuur voorkomt dat verschillende paginacontexten door elkaar lopen en maakt contentbeheer voorspelbaar.

### 2. Generieke Collectie-Renderer Met Variants

Er komt één generieke partial die bestanden uit een collectie-map combineert met metadata uit de juiste datafile. De partial ondersteunt per pagina een `collection_variant`.

Varianten:
- `brand-links`
  - voor `merken en verdelers`
  - voor `leasing fietsen`
  - strakke logo-grid, uniforme containers, optionele externe links
- `hover-cards`
  - voor `accessoires`
  - voor `modellen in de kijker`
  - beeldvullende kaart met hover-overlay waarop de titel verschijnt
- filtering wordt alleen geactiveerd als een pagina expliciet aangeeft dat filters aan moeten staan

Daardoor ontstaat één technisch systeem, maar met sobere output op maat van elk paginatype.

### 3. Gedeelde Header Met Mode-Aware Hamburgermenu

De header wordt niet gedupliceerd of visueel nagebouwd. `layouts/partials/header.html` blijft de enige bron voor headeropmaak en gedrag, en blijft via `baseof.html` op home en single pages identiek gerenderd.

De zichtbare header bevat:
- logo
- `Contact`
- mode-switch
- hamburgermenu-trigger

Het hamburgermenu toont per modus alleen relevante links.

Bikemodus:
- `Merken en verdelers`
- `Accessoires`
- `Enkele modellen in de kijker`
- `Leasing fietsen`

Drivemodus:
- `Merken en verdelers`
- `Modellen in de kijker`
- `Winteronderhoud van tuinmachines`

Mijn aanbeveling is een compacte drop-down onder de header in plaats van een zwaar off-canvas menu. Dat sluit beter aan bij de sobere stijl en hergebruikt de bestaande mode-scriptlogica eenvoudiger.

### 4. Homepage-Kaarten Met Afbeelding En Overlaytitel

De huidige homepage-kaarten worden visueel rijker door elke kaart aan een eigen afbeelding te koppelen. De kaart behoudt zijn linkdoel en modusspecifieke plaats in de grid, maar wordt gerenderd als beeldkaart met titel-overlay.

Belangrijke keuzes:
- de homepage-kaarten en het hamburgermenu lezen uit dezelfde mode-aware datastructuur in `site-mode.html`
- elke kaart ondersteunt een `title`, `summary`, `href` en `image`
- de titel blijft zichtbaar als overlay
- de samenvatting kan klein en secundair blijven of in mobile states worden ingekort

Zo voorkom je dat de homepage en het menu verschillende inhoudsbronnen krijgen.

### 5. Metadata-Model Voor Alle Collecties

Per item in een collectie is metadata mogelijk via de relevante `.toml` file. De basismodelvelden zijn:
- `title`
- `alt`
- `url`
- `weight`
- optioneel `tags`

Gebruik per paginatype:
- `merken en verdelers`: `tags`, `url`, `weight`, `alt`
- `leasing fietsen`: `url`, `weight`, `alt`
- `accessoires` en `modellen in de kijker`: `title`, `alt`, optioneel `url`, `weight`

Daarmee blijven alle collecties uitbreidbaar zonder templatewijzigingen.

### 6. Paginaspecifiek Gedrag

`Leasing fietsen` in bikeshop:
- dynamische grid
- vijf entries of meer via mapinhoud
- zelfde stijl als `merken en verdelers`
- geen filtering
- wel externe URLs per item

`Accessoires` in bikeshop:
- dynamische fotogrid
- hover-overlay met naam
- `url` optioneel ondersteund, maar niet vereist

`Modellen in de kijker` in bikeshop en driveshop:
- dynamische fotogrid
- hover-overlay met naam
- `url` optioneel ondersteund voor later gebruik

`Winteronderhoud van tuinmachines` in driveshop:
- blijft een gewone contentpagina zonder collectie-rendering

### 7. Fallback- En Foutgedrag

De collecties moeten robuust blijven bij onvolledige inhoud:
- lege map: sobere fallbackmelding
- ontbrekende metadata: titel afgeleid uit bestandsnaam, veilige alt-default
- ontbrekende `url`: item blijft zichtbaar zonder kliklink
- hover-overlay alleen bij `hover-cards`
- filterbalk alleen wanneer expliciet geactiveerd

### 8. Verificatie

De verificatie moet uitbreiden naar:
- gedeelde header-render op home en single pages via dezelfde partial-uitvoer
- aanwezigheid van een hamburgermenu-trigger en mode-specifieke menu-items
- homepage-kaarten met beeldmarkers en overlaytitels
- leasing-grid met klikbare items maar zonder filterbalk
- accessoires- en modellen-grids met hover-card markup
- `winteronderhoud van tuinmachines` zonder gallery-markers
- aanwezigheid van de nieuwe collectiebronmappen en datafiles

Basischecks blijven:
- `hugo --destination .test-public`
- `powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html`
- `hugo`

Daarnaast blijft handmatige browsercontrole belangrijk voor hamburgerinteractie, hoveroverlays en mode-aware menu-uitklappen.

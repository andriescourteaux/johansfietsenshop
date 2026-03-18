# Header, Openingsuren En Gallery Design

**Goal:** De headertypografie consistent maken tussen homepage en binnenpagina's, een eenvoudig aanpasbaar openingsurenblok op de homepage toevoegen, en de mode-specifieke merken/verdelerspagina's laten renderen vanuit afbeeldingsmappen met uitbreidbare metadata.

## Huidige Context

De site gebruikt vandaag een gedeelde header-partial in `layouts/partials/header.html`, een homepage-template in `layouts/index.html` en een generieke single-template in `layouts/_default/single.html`. De bike- en drive-versies van `merken en verdelers` bestaan al als aparte contentpagina's, maar renderen nog tekstuele placeholder-grids via front matter arrays.

## Ontwerpkeuzes

### 1. Consistente Headertypografie

De homepage-header heeft vandaag een aparte overlay-styling in `assets/css/style.css`, waardoor de visuele typografie afwijkt van `contact` en `merken en verdelers`. De oplossing is om de typografische stijl van de navigatie centraal te maken, zodat font, gewicht, lettervorm, spacing en hovergedrag gelijk zijn op alle pagina's. Alleen contextuele verschillen zoals transparante achtergrond en positionering van de homepage blijven apart.

### 2. Content-gedreven Openingsuren

De openingsuren worden niet hardcoded in HTML. De homepage-content in `content/_index.md` krijgt extra front matter-velden, bijvoorbeeld een titel en een lijst regels voor de openingsuren. `layouts/index.html` rendert daaruit een sober info-blok tussen header en paginatitel binnen de hero-content. Later aanpassen blijft dan een eenvoudige markdown-wijziging.

### 3. Mode-specifieke Afbeeldingsgallery

Er komen twee bronmappen voor de galerij:
- `static/images/merken-verdelers/bikeshop/`
- `static/images/merken-verdelers/driveshop/`

De bike- en drive-pagina's voor `merken en verdelers` krijgen een gallerymodus via front matter. Een dedicated partial leest de juiste map uit, filtert op afbeeldingsbestanden, en rendert een sober responsief grid met alleen afbeeldingen. De zichtbare paginatitel blijft enkel `Merken en verdelers`.

### 4. Toekomstige Metadata Zonder Huidige Visuele Extra's

Om later tekst of extra info per afbeelding toe te voegen zonder templatewijziging, komt er optionele metadata onder `data/merken-verdelers/`, bijvoorbeeld per modus als mapping op bestandsnaam. Die metadata wordt nu al ondersteund voor zaken zoals `alt`-tekst, volgorde of latere captions, maar voorlopig niet zichtbaar gemaakt in de UI.

### 5. Lege Map Gedrag

Als een galerijmap nog geen afbeeldingen bevat, toont de pagina een sobere fallbackmelding in plaats van een leeg raster. Dat houdt de pagina functioneel terwijl de gebruiker later afbeeldingen kan toevoegen.

## Verificatie

De bestaande PowerShell-sitecheck in `tests/verify_site.ps1` wordt uitgebreid zodat die controleert op:
- openingsuren-markers vanuit de homepage-output
- consistente header- en navigatiemarkers
- de nieuwe gallery-renderhook op bike- en drive-pagina's
- de aanwezigheid van de galerijbronmappen en optionele metadata-ingang

Daarnaast blijven `hugo --destination .test-public` en `hugo` de hoofdverificaties voor build-integriteit.

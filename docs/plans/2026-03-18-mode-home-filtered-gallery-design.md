# Mode-Aware Homeflow En Filterbare Merken Design

**Goal:** Vereenvoudig de header, maak de homepage per modus de centrale navigatie-ingang met eigen landingstegels, en breid `merken en verdelers` uit naar een strakke filterbare merkengrid met klikbare externe merklinks.

## Huidige Context

De site heeft vandaag al een mode-aware homepagina met bike- en drive-modus, een gedeelde contactpagina, en twee mode-specifieke `merken en verdelers` pagina's. De header toont nog `Contact`, `Merken en verdelers` en de mode-switch. De homepage toont nog een vaste set generieke tegels, en de merkenpagina's renderen een eenvoudige afbeeldingsgrid zonder filtering.

De bestaande mode-logica zit gecentraliseerd in `layouts/partials/site-mode.html`, de header in `layouts/partials/header.html`, de homepage in `layouts/index.html`, en de galerij in `layouts/partials/merken-gallery.html` met metadata uit `data/merken-verdelers/*.toml`.

## Gekozen Aanpak

De gekozen aanpak is content-gedreven voor pagina's en data-gedreven voor de merkengrid:
- mode-specifieke homepanelen linken naar echte contentpagina's onder `/bikeshop/...` en `/driveshop/...`
- de header blijft minimaal en toont alleen `Contact` en de mode-switch
- de merkengrid blijft zijn afbeeldingen uit de mode-specifieke statische mappen lezen
- metadata zoals tags, externe merklink, alt-tekst en sortering komt uit `data/merken-verdelers/*.toml`
- filtering gebeurt client-side met lichte JavaScript

Dit houdt de inhoud eenvoudig beheersbaar in Markdown en TOML, zonder dat redactiewerk afhankelijk wordt van template-aanpassingen.

## Ontwerpkeuzes

### 1. Minimale Header En Centrale Homepage

De header wordt teruggebracht tot twee functionele elementen:
- `Contact`
- de mode-switch `Bikeshop` of `Driveshop`

`Merken en verdelers` verdwijnt uit de header. De homepage blijft de centrale ingang per modus, zodat bezoekers daar de relevante inhoudstegels krijgen te zien afhankelijk van de actieve mode.

### 2. Mode-Specifieke Homepanelen

De homepage rendert twee verschillende kaartsets.

In bikemodus:
- `Merken en verdelers`
- `Accessoires`
- `Enkele modellen in de kijker`
- `Leasing fietsen`

In drivemodus:
- `Merken en verdelers`
- `Modellen in de kijker`
- `Winteronderhoud van tuinmachines`

Elke tegel verwijst naar een eigen pagina. `Contact` blijft een gedeelde pagina buiten deze kaartsets.

### 3. Nieuwe Paginastructuur

De beoogde content-URL's zijn:

Bike:
- `/bikeshop/merken-en-verdelers/`
- `/bikeshop/accessoires/`
- `/bikeshop/modellen-in-de-kijker/`
- `/bikeshop/leasing-fietsen/`

Drive:
- `/driveshop/merken-en-verdelers/`
- `/driveshop/modellen-in-de-kijker/`
- `/driveshop/winteronderhoud-van-tuinmachines/`

Gedeeld:
- `/`
- `/contact/`

Deze structuur houdt de inhoud per modus expliciet gescheiden en voorkomt dat de homepage opnieuw moet dienen als vervanging voor aparte contentpagina's.

### 4. Strakkere Merken- En Verdelersgrid

Beide `merken en verdelers` pagina's krijgen dezelfde visuele gridregels:
- 3 kolommen op desktop
- 2 kolommen op tablet
- 1 kolom op mobiel
- consistente kaartbreedte en afbeeldingscontainer
- sobere presentatie zonder zichtbare titel of tekst per merkkaart

De grid blijft visueel gericht op de afbeeldingen. De enige vaste tekst op de pagina blijft de paginatitel `Merken en verdelers`.

### 5. Metadata En Klikbare Merken

Per afbeelding kan in `data/merken-verdelers/bikeshop.toml` of `data/merken-verdelers/driveshop.toml` metadata worden opgeslagen, gemapt op bestandsnaam. Elk item ondersteunt:
- `title`
- `alt`
- `tags = []`
- `url`
- `weight`

De UI toont voorlopig alleen de afbeelding, maar gebruikt die metadata voor:
- toegankelijke alt-tekst
- sortering
- filtertags
- externe kliklink naar de merkwebsite

Als `url` aanwezig is, wordt de afbeelding klikbaar en opent de merkwebsite in een nieuw tabblad. Als `url` ontbreekt, blijft het item zichtbaar maar zonder externe link.

### 6. Multi-Tag Filtering

Boven de grid komt een compacte filterbalk met:
- een `Alles`-knop
- automatisch opgebouwde tagknoppen uit de metadata

Bezoekers kunnen meerdere tags tegelijk selecteren. De gekozen filterlogica is `OR`:
- een merk blijft zichtbaar als het minstens een van de actieve tags bevat

Die keuze past beter bij showroomverkenning dan `AND`, omdat bezoekers dan niet te snel op een schijnbaar lege pagina uitkomen.

Filtering gebeurt client-side zonder page reload, via `data-tags` op grid-items en een kleine JS-controller.

### 7. Fallback- En Foutgedrag

De pagina's blijven robuust bij onvolledige inhoud:
- items zonder metadata renderen met veilige defaults
- items zonder `tags` blijven zichtbaar onder `Alles`
- items zonder `url` blijven niet-clickable
- lege galerijmappen tonen een sobere fallbackmelding

Zo kan inhoud incrementeel worden toegevoegd zonder dat de pagina breekt.

## Verificatie

Voor deze feature moet de verificatie uitbreiden naar:
- minimale headernavigatie op home en binnenpagina's
- mode-specifieke tegelsets op de homepage
- aanwezigheid van de nieuwe bike- en drive-contentpagina's
- 3-koloms gallery-markup en consistente beeldcontainers
- filterknoppen en `data-tags` rendering
- externe merklinks wanneer `url` is ingesteld

De basiscontroles blijven:
- `hugo --destination .test-public`
- `powershell -ExecutionPolicy Bypass -File tests/verify_site.ps1 -PublicDir .test-public -CssPath assets/css/style.css -HeadTemplatePath layouts/partials/head.html`
- `hugo`

Daarnaast is handmatige browsercontrole nodig voor mode-switching, responsive homepanelen en filtergedrag.

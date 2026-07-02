# Models Showcase Design

**Doel**

De pagina's `modellen in de kijker` krijgen een rijkere, scrollende productpresentatie in plaats van de bestaande eenvoudige grid. Elk model wordt een eigen showcase-sectie met groot beeld, korte intro en scanbare specs.

**Reikwijdte**

- geldt alleen voor bike- en drive-pagina's `modellen in de kijker`
- geen carrousel
- afwisselende layout: beeld links/info rechts, daarna omgekeerd
- mobiel onder elkaar
- bestaande collectievarianten voor `merken`, `leasing` en `accessoires` blijven intact

**Aanpak**

- `media-collection.html` krijgt een nieuwe `showcase`-variant
- de modellen-datafiles krijgen rijkere velden: `title`, `alt`, `image`, `intro`, `specs`, optioneel `url`
- de mode-specifieke modellenpagina's wijzen naar `collection_variant = "showcase"`
- `style.css` krijgt de afwisselende showcase-layout en lichte motion hooks
- `verify_site.ps1` controleert dat de modellenpagina's de showcase-markup renderen zonder de andere collectievarianten te breken

**Visuele richting**

Elke modelssectie bevat:

- groot beeld
- modelnaam
- korte intro
- compacte specs-lijst
- optionele link later

De layout wisselt per item af:

- item 1: beeld links, info rechts
- item 2: info links, beeld rechts
- item 3: beeld links, info rechts

Dat geeft ritme zonder de frictie van een slider. De motion blijft subtiel en performantiegericht.

**Verificatie**

Na implementatie moet minimaal gecontroleerd worden:

- beide modellenpagina's renderen de showcase-variant
- intro en specs zijn zichtbaar in de output
- layout-hooks voor afwisselende volgorde bestaan
- mobiel blijft leesbaar
- merken/accessoires/leasing blijven op hun bestaande varianten draaien

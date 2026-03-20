# Sticky Header UI Polish Design

**Doel**

Deze polishronde werkt de resterende UI-inconsistenties weg in de bestaande Hugo-site, zonder de huidige architectuur te verbreden. De focus ligt op headergedrag, openingsurenweergave, hover-consistentie, contactaccenten en een paar visuele correcties die nu nog verkeerd of onduidelijk aanvoelen.

**Reikwijdte**

- Het hoofdlogo blijft altijd volledig zichtbaar; geen fade-hover meer.
- `Contact` verhuist naar de laatste positie in het hamburgermenu voor bike- en drive-modus.
- De home-tabel blijft openingsuren op `|` opsplitsen naar meerdere regels.
- De footer toont opnieuw de authored plain text met pipe, zonder split.
- Het contactformulier krijgt duidelijkere borders.
- `Merken en verdelers`, `modellen in de kijker`, `accessoires` en `leasing fietsen` krijgen dezelfde hover-motion als de homecards.
- Filtertags renderen in uppercase in plaats van small-caps.
- Homecards verliezen hun border.
- Contactaccenten worden echt mode-aware: geel in bike, rood in drive.
- De header wordt sticky aan de top van het scherm.
- De sticky header krijgt twee instelbare gradient-states:
  - standaard: huidige gradient
  - gescrolld: dezelfde gradientfamilie, maar iets minder transparant aan de lichtste stop

**Aanpak**

De wijziging blijft een gerichte polish op de bestaande structuur:

- `layouts/partials/header.html`, `layouts/partials/site-mode.html` en `layouts/partials/mode-script.html` regelen de menustructuur, sticky/scrolled state en de volgorde van menu-items.
- `layouts/index.html`, `layouts/partials/footer.html` en `layouts/partials/opening-hours-data.html` scheiden tabelrendering en footerrendering voor openingsuren.
- `layouts/partials/media-collection.html` en `assets/css/style.css` krijgen gedeelde hover- en filterpolish.
- `layouts/_default/single.html` en `assets/css/style.css` herstellen de contactaccenten en de zichtbaarheid van de formuliervelden.

**Header en sticky gedrag**

De header blijft een gedeelde partial. De verandering zit in gedrag en styling, niet in duplicatie:

- de header wordt sticky met een hoge `z-index`
- de hero/banner scrollt eronder door
- het logo houdt altijd volle opacity, ook in overlay-state en hover-state
- `Contact` blijft alleen in het dropdownmenu
- in beide mode-menu’s komt `Contact` als laatste item
- een lichte scroll hook schakelt een `scrolled` state op de header of `body`
- twee expliciete gradientwaarden blijven eenvoudig aanpasbaar in CSS

**Openingsuren**

De urenrendering wordt bewust opgesplitst:

- de home-tabel gebruikt de gesplitste datastructuur uit `opening-hours-data.html`
- de footer leest rechtstreeks uit de authored `opening_hours` array

Daarmee krijg je:

- tabel: pipe wordt omgezet naar meerregelige uurvakken
- footer: pipe blijft letterlijk zichtbaar

**Cards en filters**

De kaartbeweging wordt gecentraliseerd zodat homecards en collectiekaarten hetzelfde aanvoelen:

- lichte lift op hover
- lichte image zoom
- iets sterkere overlay
- dezelfde timing en reduced-motion guard als de bestaande homecards

Filtertags behouden hun huidige blokstructuur, maar schakelen over van `small-caps` naar echte uppercase styling.

**Contactpagina**

De contactpagina blijft inhoudelijk hetzelfde, maar wordt visueel gecorrigeerd:

- accentkleur volgt de actieve modus via centrale CSS-variabelen
- `Johan Alliet` en de labels (`Adres:`, `GSM:`, `E-mail:` ...) gebruiken die accentkleur
- de inputvelden krijgen terug duidelijke borders
- focus state blijft subtiel maar leesbaar

**Verificatie**

Na implementatie moet minimaal gecontroleerd worden:

- `Contact` staat als laatste in beide mode-menu’s
- het logo blijft altijd volle opacity
- de header is sticky en heeft een aparte scrolled-state hook
- de home-tabel splitst pipe-uren nog steeds op meerdere regels
- de footer toont pipe-uren nog letterlijk
- homecards hebben geen rand meer
- collectiekaarten gebruiken dezelfde hover markers of beweging als homecards
- filtertags zijn uppercase
- contactaccent is geel in bike en rood in drive

**Niet in scope**

- geen nieuwe contentmodellen
- geen wijziging aan de algemene pagina-architectuur
- geen wijziging aan de bestaande hero-parallaxlogica buiten de sticky header-interactie

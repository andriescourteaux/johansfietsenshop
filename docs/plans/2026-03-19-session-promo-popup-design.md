# Session Promo Popup Design

**Doel**

Deze feature voegt een sitebrede promotie-popup toe die losstaat van de rest van de websiteflow. Bij het eerste bezoek in een browser- of tab-sessie verschijnt een centrale popup met een promotie-afbeelding. Zodra de bezoeker die sluit, blijft ze weg tot de sessie eindigt.

**Reikwijdte**

- De popup is globaal beschikbaar op de hele site.
- De popup toont voorlopig alleen een afbeelding en een sluitknop.
- De popup is niet fullscreen; ze verschijnt als een gecentreerde modal-card met subtiele backdrop.
- Sluiten bewaart een sessieflag in `sessionStorage`.
- De popup verschijnt opnieuw bij een nieuwe browser- of tab-sessie.
- De feature moet eenvoudig uitgeschakeld kunnen worden wanneer de promotie voorbij is.

**Aanpak**

De feature blijft bewust losgekoppeld van bike/drive mode, de homepageflow en de bestaande contentstructuren:

- `data/promo-popup.toml` beheert of de popup actief is en welke afbeelding geladen wordt.
- `layouts/partials/promo-popup.html` rendert de globale popup-markup alleen als de datafile `enabled = true` heeft.
- `layouts/_default/baseof.html` laadt die partial sitebreed in.
- `layouts/partials/promo-popup-script.html` regelt het sessiegedrag met `sessionStorage`.
- `assets/css/style.css` krijgt lichte modal-styling zonder zware effecten of performancekost.

**Popupgedrag**

De popup volgt deze regels:

- tonen bij eerste page load als de popup actief is
- sluiten via de sluitknop
- sluiten via klik op de backdrop
- binnen dezelfde browser- of tab-sessie niet meer opnieuw tonen
- bij een nieuwe sessie opnieuw tonen
- geen cookies of langdurige opslag; alleen `sessionStorage`

Omdat de popup enkel een afbeelding toont, blijft de interactie eenvoudig en voorspelbaar. Er komt dus voorlopig geen link, CTA-knop of modusspecifieke variatie.

**Beheer**

Beheer moet zonder templatewijzigingen mogelijk blijven. Daarom krijgt de datafile minimaal:

```toml
enabled = true
image = "/images/promo/actie.webp"
alt = "Promotie"
```

Daarmee wordt de onderhoudsflow:

- nieuwe promotie: andere afbeelding instellen en `enabled = true`
- promotie voorbij: `enabled = false`
- geen codewijziging nodig voor dagelijks beheer

**Rendering en styling**

De popup blijft visueel licht:

- centrale kaart met beperkte breedte
- afbeelding binnen de kaart
- subtiele backdrop
- duidelijke sluitknop
- lichte fade/slide bij openen en sluiten, maar zonder zware blur, filters of layout thrash
- correcte reduced-motion fallback

Omdat de popup los staat van de site-mode-logica, wordt ze ook niet mode-aware gemaakt. Dat houdt de feature eenvoudiger en voorkomt extra onderhoudslast.

**Verificatie**

Na implementatie moet minimaal gecontroleerd worden:

- popup-markup rendert als `enabled = true`
- popup-markup rendert niet als `enabled = false`
- image-bron komt uit de datafile
- sluitknop en backdrop hooks zijn aanwezig
- de globale layout blijft intact
- de popup verschijnt één keer per sessie en blijft weg na sluiten tot de sessie eindigt

**Niet in scope**

- geen klikbare promotielink
- geen modusspecifieke popup
- geen server-side targeting of datumlogica
- geen cookie- of localStorage-persistentie over meerdere sessies heen

# Local Roboto Font Design

**Goal:** De site volledig op een sobere, niet-serif typografie zetten met Roboto als lokaal gehost lettertype zonder externe requests.

## Scope

De wijziging blijft beperkt tot de bestaande stylesheet en verificatie. We gebruiken de aanwezige fontbestanden in `static/fonts/` en voegen geen externe fontprovider of buildstap toe.

## Approach

De site krijgt self-hosted `@font-face`-definities voor Roboto regular, italic, bold en bold italic. De algemene typografie blijft via `body` erven, zodat navigatie, headings, formulieren en content overal dezelfde sans-richting volgen zonder extra componentlogica.

## Verification

De bestaande PowerShell-check wordt uitgebreid zodat die controleert op lokale Roboto-fontbronnen en op een expliciete Roboto sans-stack in de CSS. Daarna worden `hugo --destination .test-public`, het verificatiescript en een gewone `hugo` build opnieuw uitgevoerd.

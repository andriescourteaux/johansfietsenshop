param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$popupTemplate = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/promo-popup.html"), [System.Text.Encoding]::UTF8)
$modeScript = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/mode-script.html"), [System.Text.Encoding]::UTF8)
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)
$homePath = Join-Path $repoRoot (Join-Path $PublicDir "index.html")
$contactPath = Join-Path $repoRoot (Join-Path $PublicDir "contact/index.html")
$homeHtml = if (Test-Path $homePath) { [System.IO.File]::ReadAllText($homePath, [System.Text.Encoding]::UTF8) } else { "" }
$contactHtml = if (Test-Path $contactPath) { [System.IO.File]::ReadAllText($contactPath, [System.Text.Encoding]::UTF8) } else { "" }

$problems = @()
$whiteBikeLogo = "static/images/logo_bike_white.webp"
$whiteDriveLogo = "static/images/logo_drive_white.webp"
foreach ($logoPath in @($whiteBikeLogo, $whiteDriveLogo)) {
    if (-not (Test-Path (Join-Path $repoRoot $logoPath))) {
        $problems += "Missing $logoPath."
    }
}

if (-not $popupTemplate.Contains('partial "site-mode.html"')) {
    $problems += "Popup template must reuse site-mode logo data."
}

if (
    -not $popupTemplate.Contains('logo_bike_white.webp') -or
    -not $popupTemplate.Contains('logo_drive_white.webp') -or
    -not $popupTemplate.Contains('src="{{ $popupLogoPath }}"') -or
    -not $popupTemplate.Contains('data-bike-src="{{ $popupLogoBikePath }}"') -or
    -not $popupTemplate.Contains('data-drive-src="{{ $popupLogoDrivePath }}"')
) {
    $problems += "Popup template must point its logo at the white bike and drive logo paths."
}

foreach ($page in @(@{ Name = "layouts/partials/promo-popup.html"; Html = $popupTemplate }, @{ Name = "index.html"; Html = $homeHtml }, @{ Name = "contact/index.html"; Html = $contactHtml })) {
    if (-not [regex]::IsMatch($page.Html, 'promo-popup__frame.*promo-popup__chrome.*promo-popup__logo.*promo-popup__close.*promo-popup__dialog', 'Singleline')) {
        $problems += "$($page.Name) must render popup logo and close button above the dialog."
    }

    if ([regex]::IsMatch($page.Html, '<div class="promo-popup__dialog"[^>]*>\s*<button class="promo-popup__close"', 'Singleline')) {
        $problems += "$($page.Name) must not keep the close button inside the dialog."
    }
}

foreach ($page in @(@{ Name = "index.html"; Html = $homeHtml }, @{ Name = "contact/index.html"; Html = $contactHtml })) {
    if (-not [regex]::IsMatch($page.Html, 'class="promo-popup__logo"[^>]*(?:src|data-bike-src)="[^"]*logo_bike_white\.webp"[^>]*data-drive-src="[^"]*logo_drive_white\.webp"')) {
        $problems += "Generated $($page.Name) popup must use the white bike and drive logos."
    }
}

if (-not [regex]::IsMatch($css, '\.promo-popup__frame\s*\{(?=[^}]*width\s*:\s*min\(52vw,\s*52rem\))(?=[^}]*transition\s*:\s*transform)', 'Singleline')) {
    $problems += "Popup frame must own the dialog width and animation."
}

if (-not [regex]::IsMatch($css, '\.promo-popup__chrome\s*\{(?=[^}]*display\s*:\s*flex)(?=[^}]*justify-content\s*:\s*space-between)(?=[^}]*align-items\s*:\s*center)', 'Singleline')) {
    $problems += "Popup chrome must align logo left and close button right."
}

if (-not [regex]::IsMatch($css, '\.promo-popup__logo\s*\{[^}]*height\s*:\s*clamp\(', 'Singleline')) {
    $problems += "Popup logo needs its own size rule."
}

$closeRule = [regex]::Match($css, '\.promo-popup__close\s*\{[^}]*\}', 'Singleline').Value
if ($closeRule.Contains("position: absolute") -or $closeRule.Contains("top:") -or $closeRule.Contains("right:")) {
    $problems += "Popup close button must be outside the dialog flow, not absolutely placed in it."
}

if (-not $css.Contains('.promo-popup[data-state="opening"] .promo-popup__frame')) {
    $problems += "Popup open animation must target the frame so the chrome moves with the dialog."
}

if (-not [regex]::IsMatch($css, '@media\s*\(max-width:\s*640px\).*\.promo-popup__dialog\s*\{[^}]*max-height\s*:\s*calc\(100dvh\s*-\s*5\.5rem\)', 'Singleline')) {
    $problems += "Mobile popup dialog height must leave room for the logo and close button above it."
}

if (-not [regex]::IsMatch($modeScript, 'querySelectorAll\(''\.site-brand__logo,\s*\.promo-popup__logo''\).*logos\.forEach', 'Singleline')) {
    $problems += "Mode script must update both header and popup logos."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Promo popup chrome checks passed."

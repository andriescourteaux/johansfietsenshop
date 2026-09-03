param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$popupTemplate = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/promo-popup.html"), [System.Text.Encoding]::UTF8)
$scriptTemplate = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/promo-popup-script.html"), [System.Text.Encoding]::UTF8)
$homePath = Join-Path $repoRoot (Join-Path $PublicDir "index.html")
$contactPath = Join-Path $repoRoot (Join-Path $PublicDir "contact/index.html")
$homeHtml = if (Test-Path $homePath) { [System.IO.File]::ReadAllText($homePath, [System.Text.Encoding]::UTF8) } else { "" }
$contactHtml = if (Test-Path $contactPath) { [System.IO.File]::ReadAllText($contactPath, [System.Text.Encoding]::UTF8) } else { "" }

$problems = @()
if (-not [regex]::IsMatch($popupTemplate, '<a class="promo-popup__cta"[^>]*data-promo-popup="cta"')) {
    $problems += "Popup CTA must expose a data hook for dismissal."
}

foreach ($page in @(@{ Name = "index.html"; Html = $homeHtml }, @{ Name = "contact/index.html"; Html = $contactHtml })) {
    if (-not [regex]::IsMatch($page.Html, '<a class="promo-popup__cta"[^>]*href="[^"]*contact/"[^>]*data-promo-popup="cta"')) {
        $problems += "Generated $($page.Name) popup CTA must include the dismiss hook."
    }
}

if (-not $scriptTemplate.Contains("const cta = root.querySelector('[data-promo-popup=""cta""]');")) {
    $problems += "Popup script must find the CTA dismiss hook."
}

if (-not [regex]::IsMatch($scriptTemplate, 'const\s+dismissPopup\s*=\s*\(\)\s*=>\s*\{[^}]*sessionStorage\.setItem\(storageKey,\s*''1''\)', 'Singleline')) {
    $problems += "Popup script must centralize session dismissal."
}

if (-not [regex]::IsMatch($scriptTemplate, 'cta\?\.addEventListener\(''click'',\s*dismissPopup\)')) {
    $problems += "Popup CTA click must dismiss this session before navigation."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Promo popup CTA dismissal checks passed."

param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)

$pages = @(
    @{ Path = "driveshop/winteronderhoud-van-tuinmachines/index.html"; Class = "winter-page" },
    @{ Path = "contact/index.html"; Class = "contact-page" },
    @{ Path = "over-ons/index.html"; Class = "about-page" }
)

$problems = @()
foreach ($page in $pages) {
    $htmlPath = Join-Path $repoRoot (Join-Path $PublicDir $page.Path)
    $html = if (Test-Path $htmlPath) { [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8) } else { "" }
    if (-not [regex]::IsMatch($html, '<section class="page-intro[^"]*page-intro--after-hero[^"]*">.*class="' + $page.Class, 'Singleline')) {
        $problems += "Missing expected $($page.Class) page canvas in generated $($page.Path)."
    }

    if (-not [regex]::IsMatch($css, '@media\s*\(max-width:\s*720px\).*\.page-intro--after-hero\s+\.container:has\(\.' + $page.Class + '\)[^{]*\{[^}]*width\s*:\s*100%', 'Singleline')) {
        $problems += "$($page.Class) canvas must be full-width in phone mode."
    }
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Phone canvas checks passed."

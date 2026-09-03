param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$cssPath = Join-Path $repoRoot "assets/css/style.css"
$css = [System.IO.File]::ReadAllText($cssPath, [System.Text.Encoding]::UTF8)
$cssLines = [System.IO.File]::ReadAllLines($cssPath, [System.Text.Encoding]::UTF8)

$phoneBlocks = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $cssLines.Length; $i++) {
    if ($cssLines[$i] -notmatch '@media\s*\(max-width:\s*720px\)') {
        continue
    }

    $depth = 0
    $block = @()
    for ($j = $i; $j -lt $cssLines.Length; $j++) {
        $line = $cssLines[$j]
        $block += $line
        $depth += [regex]::Matches($line, '\{').Count
        $depth -= [regex]::Matches($line, '\}').Count
        if ($depth -eq 0 -and $j -gt $i) {
            break
        }
    }
    $phoneBlocks.Add(($block -join "`n"))
}
$phoneCss = $phoneBlocks -join "`n"

$pages = @(
    "driveshop/winteronderhoud-van-tuinmachines/index.html",
    "contact/index.html",
    "over-ons/index.html"
)

$problems = @()
foreach ($page in $pages) {
    $htmlPath = Join-Path $repoRoot (Join-Path $PublicDir $page)
    $html = if (Test-Path $htmlPath) { [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8) } else { "" }
    if (-not $html.Contains("page-value")) {
        $problems += "Generated $page must render page value cards."
    }
}

if (-not [regex]::IsMatch($phoneCss, '\.page-value\s*\{(?=[^}]*min-width\s*:\s*0)(?=[^}]*padding\s*:\s*clamp\()', 'Singleline')) {
    $problems += "Page values must reduce padding and allow grid shrinkage in phone mode."
}

if (-not [regex]::IsMatch($phoneCss, '\.page-value\s+h2\s*\{(?=[^}]*font-size\s*:\s*clamp\()(?=[^}]*line-height\s*:)(?=[^}]*overflow-wrap\s*:\s*anywhere)', 'Singleline')) {
    $problems += "Page value titles must scale and wrap in phone mode."
}

if (-not [regex]::IsMatch($phoneCss, '\.page-value\s+p,\s*\.winter-value\.page-value\s+p\s*\{(?=[^}]*font-size\s*:\s*clamp\()(?=[^}]*line-height\s*:)(?=[^}]*overflow-wrap\s*:\s*anywhere)', 'Singleline')) {
    $problems += "Page value text must scale and wrap in phone mode, including winter values."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Mobile page value checks passed."

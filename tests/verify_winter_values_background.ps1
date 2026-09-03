param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)
$pagePath = Join-Path $repoRoot (Join-Path $PublicDir "driveshop/winteronderhoud-van-tuinmachines/index.html")
$html = if (Test-Path $pagePath) { [System.IO.File]::ReadAllText($pagePath, [System.Text.Encoding]::UTF8) } else { "" }

$problems = @()
if (-not [regex]::IsMatch($html, '<section class="winter-values">.*<div class="winter-values__grid">', 'Singleline')) {
    $problems += "Winteronderhoud page must render the winter values grid."
}

$winterRules = [regex]::Matches($css, '[^{}]*\.winter-values[^{}]*\{[^}]*\}', 'Singleline')
$hasCanvasBoundedBackground = $false
foreach ($rule in $winterRules) {
    $ruleText = $rule.Value
    if (
        [regex]::IsMatch($ruleText, 'background\s*:\s*#f4f4f4') -and
        [regex]::IsMatch($ruleText, 'margin-inline\s*:\s*calc\(var\(--page-intro-padding,\s*3rem\)\s*\*\s*-1\)') -and
        -not $ruleText.Contains("100vmax") -and
        -not $ruleText.Contains("clip-path")
    ) {
        $hasCanvasBoundedBackground = $true
    }
}

if (-not $hasCanvasBoundedBackground) {
    $problems += "Winter values background must cover the white canvas width, not bleed to the viewport."
}

if (-not [regex]::IsMatch($css, '\.page-intro\s+\.container\s*\{[^}]*--page-intro-padding\s*:\s*3rem[^}]*padding\s*:\s*var\(--page-intro-padding\)', 'Singleline')) {
    $problems += "Page intro canvas padding must expose the canvas width for inner full-width bands."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Winter values background checks passed."

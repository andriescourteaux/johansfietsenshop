param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$head = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/head.html"), [System.Text.Encoding]::UTF8)
$homePath = Join-Path $repoRoot (Join-Path $PublicDir "index.html")
$homeHtml = if (Test-Path $homePath) { [System.IO.File]::ReadAllText($homePath, [System.Text.Encoding]::UTF8) } else { "" }
$faviconPath = Join-Path $repoRoot "static/images/favicon.png"

$problems = @()
if (-not (Test-Path $faviconPath)) {
    $problems += "Missing static/images/favicon.png."
}

if (-not [regex]::IsMatch($head, '<link rel="icon" type="image/png" href="\{\{ "/images/favicon\.png" \| relURL \}\}">')) {
    $problems += "Head template must link the png favicon."
}

if (-not [regex]::IsMatch($homeHtml, '<link rel="icon" type="image/png" href="[^"]*/images/favicon\.png">')) {
    $problems += "Generated homepage must include the favicon link."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Favicon checks passed."

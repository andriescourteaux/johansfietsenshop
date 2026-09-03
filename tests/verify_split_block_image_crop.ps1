param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)
$aboutPath = Join-Path $repoRoot (Join-Path $PublicDir "over-ons/index.html")
$aboutHtml = if (Test-Path $aboutPath) { [System.IO.File]::ReadAllText($aboutPath, [System.Text.Encoding]::UTF8) } else { "" }

$problems = @()
if ([string]::IsNullOrWhiteSpace($aboutHtml)) {
    $problems += "Missing generated about page."
}
elseif (-not [regex]::IsMatch($aboutHtml, '<img class="split-block__image" src="[^"]*/images/about/headshot\.webp"', 'Singleline')) {
    $problems += "Missing expected headshot split-block image in generated about page."
}

if ([regex]::IsMatch($css, '\.split-block__image\[src\$="/images/home/advies\.webp"\]', 'Singleline')) {
    $problems += "Advice split-block image crop rule should be reverted."
}

if (-not [regex]::IsMatch($css, '\.split-block__image\[src\$="/images/about/headshot\.webp"\]\s*\{[^}]*object-position\s*:\s*top center', 'Singleline')) {
    $problems += "About headshot split-block image must be top-aligned without changing all split-block images."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Split-block image crop checks passed."

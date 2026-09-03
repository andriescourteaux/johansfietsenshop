param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$template = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/_default/single.html"), [System.Text.Encoding]::UTF8)
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)
$aboutPath = Join-Path $repoRoot (Join-Path $PublicDir "over-ons/index.html")
$aboutHtml = if (Test-Path $aboutPath) { [System.IO.File]::ReadAllText($aboutPath, [System.Text.Encoding]::UTF8) } else { "" }

$values = @(
    @{ Icon = "onderhoud.png"; Title = "Onderhoud en service na verkoop" },
    @{ Icon = "eerlijk.svg"; Title = "Eerlijk onderhoud" },
    @{ Icon = "leasing.png"; Title = "Leasing" }
)

$problems = @()
foreach ($value in $values) {
    $iconPath = Join-Path $repoRoot ("static/images/about/" + $value.Icon)
    if (-not (Test-Path $iconPath)) {
        $problems += "Missing static/images/about/$($value.Icon)."
    }

    $icon = [regex]::Escape($value.Icon)
    $title = [regex]::Escape($value.Title)
    $pattern = '<article class="about-page__value page-value">\s*<img class="about-page__value-icon" src="[^"]*images/about/' + $icon + '" alt="" loading="lazy">\s*<h2>' + $title + '</h2>'
    if (-not [regex]::IsMatch($aboutHtml, $pattern, 'Singleline')) {
        $problems += "Generated about page must render $($value.Icon) above '$($value.Title)'."
    }
}

foreach ($emojiEntity in @("&#128295;", "&#9989;", "&#128690;")) {
    if ($template.Contains($emojiEntity) -or $aboutHtml.Contains($emojiEntity)) {
        $problems += "About value titles must not include $emojiEntity."
    }
}

if (-not [regex]::IsMatch($css, '\.about-page__value-icon\s*\{[^}]*object-fit\s*:\s*contain', 'Singleline')) {
    $problems += "About value icons need a contained icon style."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "About icon checks passed."

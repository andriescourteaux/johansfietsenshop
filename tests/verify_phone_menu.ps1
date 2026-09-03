param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$header = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/header.html"), [System.Text.Encoding]::UTF8)
$script = [System.IO.File]::ReadAllText((Join-Path $repoRoot "layouts/partials/mode-script.html"), [System.Text.Encoding]::UTF8)
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)
$homePath = Join-Path $repoRoot (Join-Path $PublicDir "index.html")
$homeHtml = if (Test-Path $homePath) { [System.IO.File]::ReadAllText($homePath, [System.Text.Encoding]::UTF8) } else { "" }

$problems = @()
function Assert-Matches {
    param([string]$Content, [string]$Pattern, [string]$Message)
    if (-not [regex]::IsMatch($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        $script:problems += $Message
    }
}

Assert-Matches $header '<div class="site-nav__menu-panel">.*site-nav__menu-mode.*site-nav__mode-toggle' "Missing mode switcher inside hamburger menu panel."
Assert-Matches $script 'querySelectorAll\([^)]*site-nav__mode-toggle' "Mode script must update both header and menu switchers."
Assert-Matches $css '@media\s*\(max-width:\s*720px\).*\.site-nav\s*>\s*\.site-nav__mode-toggle\s*\{[^}]*display\s*:\s*none' "Phone CSS must hide the top-level mode switcher."
Assert-Matches $css '@media\s*\(max-width:\s*720px\).*\.site-nav__menu-mode\s*\{[^}]*display\s*:' "Phone CSS must show the menu mode switcher."
Assert-Matches $homeHtml '<div class="site-nav__menu-panel">.*site-nav__menu-mode.*Naar Johan''s Driveshop' "Generated homepage menu must contain the switcher."

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Phone menu checks passed."

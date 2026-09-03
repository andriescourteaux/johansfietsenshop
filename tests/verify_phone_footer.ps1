param(
    [string]$PublicDir = ".test-public"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$css = [System.IO.File]::ReadAllText((Join-Path $repoRoot "assets/css/style.css"), [System.Text.Encoding]::UTF8)
$homePath = Join-Path $repoRoot (Join-Path $PublicDir "index.html")
$homeHtml = if (Test-Path $homePath) { [System.IO.File]::ReadAllText($homePath, [System.Text.Encoding]::UTF8) } else { "" }

$problems = @()
if (-not [regex]::IsMatch($homeHtml, '<footer class="site-footer">', 'Singleline')) {
    $problems += "Missing generated footer."
}

if (-not [regex]::IsMatch($css, '@media\s*\(max-width:\s*720px\).*\.site-footer__inner\s*\{[^}]*align-items\s*:\s*center[^}]*text-align\s*:\s*center', 'Singleline')) {
    $problems += "Phone footer inner must center its content."
}

if (-not [regex]::IsMatch($css, '@media\s*\(max-width:\s*720px\).*\.site-footer__contact-list\s*,\s*\.site-footer__links\s*\{[^}]*justify-items\s*:\s*center', 'Singleline')) {
    $problems += "Phone footer lists must center their items."
}

if (-not [regex]::IsMatch($css, '@media\s*\(max-width:\s*720px\).*\.site-footer__hours-line\s*\{[^}]*justify-content\s*:\s*center[^}]*text-align\s*:\s*center', 'Singleline')) {
    $problems += "Phone footer opening hours must center their rows."
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host "Phone footer checks passed."

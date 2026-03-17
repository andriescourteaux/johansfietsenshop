param(
    [Parameter(Mandatory = $true)]
    [string]$PublicDir,

    [string]$CssPath
)

$expectedPages = @(
    @{ Path = 'index.html'; Title = $null },
    @{ Path = 'contact/index.html'; Title = 'Contact' },
    @{ Path = 'merken-en-verdelers/index.html'; Title = 'Merken en verdelers' },
    @{ Path = 'driveshop/index.html'; Title = 'Driveshop' },
    @{ Path = 'bikeshop/index.html'; Title = 'Bikeshop' }
)

$navLabels = @(
    'Contact',
    'Bikeshop',
    'Driveshop',
    'Merken en verdelers'
)

$problems = @()

foreach ($page in $expectedPages) {
    $fullPath = Join-Path $PublicDir $page.Path
    if (-not (Test-Path $fullPath)) {
        $problems += ('Missing generated file: ' + $page.Path)
        continue
    }

    $html = Get-Content $fullPath -Raw

    foreach ($label in $navLabels) {
        if ($html -notmatch [regex]::Escape($label)) {
            $problems += ('Missing navigation label "' + $label + '" in ' + $page.Path)
        }
    }

    if ($page.Title -and $html -notmatch [regex]::Escape($page.Title)) {
        $problems += ('Missing page title "' + $page.Title + '" in ' + $page.Path)
    }
}

if ($CssPath) {
    if (-not (Test-Path $CssPath)) {
        $problems += ('Missing CSS file: ' + $CssPath)
    }
    else {
        $css = Get-Content $CssPath -Raw
        if ($css -notmatch '@media') {
            $problems += ('Missing responsive breakpoint in CSS file: ' + $CssPath)
        }
    }
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'

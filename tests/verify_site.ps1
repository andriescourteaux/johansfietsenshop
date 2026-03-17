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
$homeHtml = $null
$contactHtml = $null

foreach ($page in $expectedPages) {
    $fullPath = Join-Path $PublicDir $page.Path
    if (-not (Test-Path $fullPath)) {
        $problems += ('Missing generated file: ' + $page.Path)
        continue
    }

    $html = Get-Content $fullPath -Raw

    if ($page.Path -eq 'index.html') {
        $homeHtml = $html
    }

    if ($page.Path -eq 'contact/index.html') {
        $contactHtml = $html
    }

    foreach ($label in $navLabels) {
        if ($html -notmatch [regex]::Escape($label)) {
            $problems += ('Missing navigation label "' + $label + '" in ' + $page.Path)
        }
    }

    if ($page.Title -and $html -notmatch [regex]::Escape($page.Title)) {
        $problems += ('Missing page title "' + $page.Title + '" in ' + $page.Path)
    }
}

if ($homeHtml) {
    $homeChecks = @(
        'home-hero',
        '/images/hero-placeholder.svg',
        'site-header--overlay',
        'Een sobere Nederlandstalige basiswebsite'
    )

    foreach ($check in $homeChecks) {
        if ($homeHtml -notmatch [regex]::Escape($check)) {
            $problems += ('Missing homepage hero marker "' + $check + '" in index.html')
        }
    }
}

if ($contactHtml) {
    $contactChecks = @(
        '<form',
        'name="name"',
        'name="email"',
        'name="subject"',
        '<textarea',
        'Online verzending is nog niet actief.'
    )

    foreach ($check in $contactChecks) {
        if ($contactHtml -notmatch [regex]::Escape($check)) {
            $problems += ('Missing contact form marker "' + $check + '" in contact/index.html')
        }
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

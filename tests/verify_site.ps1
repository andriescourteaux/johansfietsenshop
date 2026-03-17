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
$merkenHtml = $null
$driveshopHtml = $null
$bikeshopHtml = $null

foreach ($page in $expectedPages) {
    $fullPath = Join-Path $PublicDir $page.Path
    if (-not (Test-Path $fullPath)) {
        $problems += ('Missing generated file: ' + $page.Path)
        continue
    }

    $html = Get-Content $fullPath -Raw

    switch ($page.Path) {
        'index.html' { $homeHtml = $html }
        'contact/index.html' { $contactHtml = $html }
        'merken-en-verdelers/index.html' { $merkenHtml = $html }
        'driveshop/index.html' { $driveshopHtml = $html }
        'bikeshop/index.html' { $bikeshopHtml = $html }
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

if ($driveshopHtml) {
    $driveshopChecks = @(
        'content-highlights',
        'Neem contact op voor Driveshop'
    )

    foreach ($check in $driveshopChecks) {
        if ($driveshopHtml -notmatch [regex]::Escape($check)) {
            $problems += ('Missing driveshop content marker "' + $check + '" in driveshop/index.html')
        }
    }
}

if ($bikeshopHtml) {
    $bikeshopChecks = @(
        'content-highlights',
        'Neem contact op voor Bikeshop'
    )

    foreach ($check in $bikeshopChecks) {
        if ($bikeshopHtml -notmatch [regex]::Escape($check)) {
            $problems += ('Missing bikeshop content marker "' + $check + '" in bikeshop/index.html')
        }
    }
}

if ($merkenHtml) {
    $merkenChecks = @(
        'brands-placeholder-grid',
        'dealers-placeholder-grid',
        'Merken in opbouw',
        'Verdelers in opbouw'
    )

    foreach ($check in $merkenChecks) {
        if ($merkenHtml -notmatch [regex]::Escape($check)) {
            $problems += ('Missing merken en verdelers marker "' + $check + '" in merken-en-verdelers/index.html')
        }
    }
}

if ($CssPath) {
    if (-not (Test-Path $CssPath)) {
        $problems += ('Missing CSS file: ' + $CssPath)
    }
    else {
        $css = Get-Content $CssPath -Raw
        $cssChecks = @(
            '@media (max-width: 720px)',
            '@media (max-width: 640px)',
            'contact-panel',
            'content-highlights__grid',
            'brands-placeholder-grid',
            'dealers-placeholder-grid'
        )

        foreach ($check in $cssChecks) {
            if ($css -notmatch [regex]::Escape($check)) {
                $problems += ('Missing CSS marker "' + $check + '" in ' + $CssPath)
            }
        }
    }
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'

param(
    [Parameter(Mandatory = $true)]
    [string]$PublicDir,

    [string]$CssPath,

    [string]$HeadTemplatePath
)

function Add-Problem {
    param([string]$Message)
    $script:problems += $Message
}

function Read-Html {
    param([string]$RelativePath)
    $fullPath = Join-Path $PublicDir $RelativePath
    if (-not (Test-Path $fullPath)) {
        Add-Problem ('Missing generated file: ' + $RelativePath)
        return $null
    }

    return Get-Content $fullPath -Raw
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Marker,
        [string]$Context
    )

    if ($null -eq $Content -or $Content -notmatch [regex]::Escape($Marker)) {
        Add-Problem ('Missing marker "' + $Marker + '" in ' + $Context)
    }
}

function Assert-NotContains {
    param(
        [string]$Content,
        [string]$Marker,
        [string]$Context
    )

    if ($null -ne $Content -and $Content -match [regex]::Escape($Marker)) {
        Add-Problem ('Unexpected marker "' + $Marker + '" in ' + $Context)
    }
}

function Assert-PathExists {
    param(
        [string]$TargetPath,
        [string]$Description
    )

    if (-not (Test-Path $TargetPath)) {
        Add-Problem ('Missing path: ' + $Description + ' (' + $TargetPath + ')')
    }
}

function Assert-AllContains {
    param(
        [string]$Content,
        [string[]]$Markers,
        [string]$Context
    )

    foreach ($marker in $Markers) {
        Assert-Contains $Content $marker $Context
    }
}

$problems = @()

$homeHtml = Read-Html 'index.html'
$contactHtml = Read-Html 'contact/index.html'
$bikeMerkenHtml = Read-Html 'bikeshop/merken-en-verdelers/index.html'
$driveMerkenHtml = Read-Html 'driveshop/merken-en-verdelers/index.html'
$bikeAccessoriesHtml = Read-Html 'bikeshop/accessoires/index.html'
$bikeModelsHtml = Read-Html 'bikeshop/modellen-in-de-kijker/index.html'
$bikeLeasingHtml = Read-Html 'bikeshop/leasing-fietsen/index.html'
$driveModelsHtml = Read-Html 'driveshop/modellen-in-de-kijker/index.html'
$driveWinterHtml = Read-Html 'driveshop/winteronderhoud-van-tuinmachines/index.html'

foreach ($pathSpec in @(
    @{ Path = 'static/images/collecties/bikeshop/merken-en-verdelers'; Description = 'bike brands collection directory' },
    @{ Path = 'static/images/collecties/bikeshop/leasing-fietsen'; Description = 'bike leasing collection directory' },
    @{ Path = 'static/images/collecties/bikeshop/accessoires'; Description = 'bike accessories collection directory' },
    @{ Path = 'static/images/collecties/bikeshop/modellen-in-de-kijker'; Description = 'bike models collection directory' },
    @{ Path = 'static/images/collecties/driveshop/merken-en-verdelers'; Description = 'drive brands collection directory' },
    @{ Path = 'static/images/collecties/driveshop/modellen-in-de-kijker'; Description = 'drive models collection directory' },
    @{ Path = 'data/collecties/bikeshop/merken-en-verdelers.toml'; Description = 'bike brands collection data file' },
    @{ Path = 'data/collecties/bikeshop/leasing-fietsen.toml'; Description = 'bike leasing collection data file' },
    @{ Path = 'data/collecties/bikeshop/accessoires.toml'; Description = 'bike accessories collection data file' },
    @{ Path = 'data/collecties/bikeshop/modellen-in-de-kijker.toml'; Description = 'bike models collection data file' },
    @{ Path = 'data/collecties/driveshop/merken-en-verdelers.toml'; Description = 'drive brands collection data file' },
    @{ Path = 'data/collecties/driveshop/modellen-in-de-kijker.toml'; Description = 'drive models collection data file' }
)) {
    Assert-PathExists $pathSpec.Path $pathSpec.Description
}

Assert-AllContains $homeHtml @(
    'home-hero',
    'home-hero__image',
    '/images/header_bike.webp',
    '/images/header_drive.webp',
    'data-shared-page="true"',
    'data-site-mode="bike"',
    'site-mode-script',
    'opening-hours',
    'data-mode-panel="bike"',
    'data-mode-panel="drive"',
    'site-nav__menu-toggle',
    'site-nav__menu',
    'site-nav__menu-shell',
    'data-mode-nav="bike"',
    'data-mode-nav="drive"',
    'overview-card__media',
    'overview-card__image',
    'overview-card__overlay',
    'Merken en verdelers',
    'Accessoires',
    'Enkele modellen in de kijker',
    'Leasing fietsen',
    'Modellen in de kijker',
    'Winteronderhoud van tuinmachines',
    'bikeshop/accessoires/',
    'bikeshop/modellen-in-de-kijker/',
    'bikeshop/leasing-fietsen/',
    'driveshop/modellen-in-de-kijker/',
    'driveshop/winteronderhoud-van-tuinmachines/'
) 'index.html'

Assert-AllContains $contactHtml @(
    '<form',
    'Online verzending is nog niet actief.',
    'data-shared-page="true"',
    'data-site-mode="bike"',
    'site-mode-script',
    'site-nav__contact',
    'site-nav__switch',
    'site-nav__menu-toggle',
    'site-nav__menu',
    'site-nav__menu-shell'
) 'contact/index.html'

Assert-NotContains $contactHtml 'site-nav__merken' 'contact/index.html'

Assert-AllContains $bikeMerkenHtml @(
    'data-site-mode="bike"',
    'site-nav__menu-toggle',
    'site-nav__menu',
    'site-nav__menu-shell',
    'data-mode-nav="bike"',
    'media-collection',
    'media-collection--brand-links',
    'data-media-collection',
    'media-collection__filters',
    'media-collection__filter',
    'data-media-item',
    'data-tags=',
    'target="_blank"',
    'rel="noopener noreferrer"'
) 'bikeshop/merken-en-verdelers/index.html'

Assert-AllContains $driveMerkenHtml @(
    'data-site-mode="drive"',
    'site-nav__menu-toggle',
    'site-nav__menu',
    'site-nav__menu-shell',
    'data-mode-nav="drive"',
    'media-collection',
    'media-collection--brand-links',
    'data-media-collection',
    'media-collection__filters',
    'media-collection__filter',
    'data-media-item',
    'data-tags=',
    'target="_blank"',
    'rel="noopener noreferrer"'
) 'driveshop/merken-en-verdelers/index.html'

Assert-AllContains $bikeLeasingHtml @(
    'Leasing fietsen',
    'data-site-mode="bike"',
    'site-nav__menu-toggle',
    'media-collection',
    'media-collection--brand-links',
    'data-media-collection',
    'data-media-item',
    'target="_blank"',
    'rel="noopener noreferrer"'
) 'bikeshop/leasing-fietsen/index.html'

Assert-NotContains $bikeLeasingHtml 'media-collection__filters' 'bikeshop/leasing-fietsen/index.html'

Assert-AllContains $bikeAccessoriesHtml @(
    'Accessoires',
    'data-site-mode="bike"',
    'site-nav__menu-toggle',
    'media-collection',
    'media-collection--hover-cards',
    'data-media-collection',
    'data-media-item',
    'media-collection__overlay',
    'media-collection__title'
) 'bikeshop/accessoires/index.html'

Assert-AllContains $bikeModelsHtml @(
    'Enkele modellen in de kijker',
    'data-site-mode="bike"',
    'site-nav__menu-toggle',
    'media-collection',
    'media-collection--hover-cards',
    'data-media-collection',
    'data-media-item',
    'media-collection__overlay',
    'media-collection__title'
) 'bikeshop/modellen-in-de-kijker/index.html'

Assert-AllContains $driveModelsHtml @(
    'Modellen in de kijker',
    'data-site-mode="drive"',
    'site-nav__menu-toggle',
    'media-collection',
    'media-collection--hover-cards',
    'data-media-collection',
    'data-media-item',
    'media-collection__overlay',
    'media-collection__title'
) 'driveshop/modellen-in-de-kijker/index.html'

Assert-AllContains $driveWinterHtml @(
    'Winteronderhoud van tuinmachines',
    'data-site-mode="drive"',
    'site-nav__menu-toggle',
    'site-nav__menu',
    'site-nav__menu-shell'
) 'driveshop/winteronderhoud-van-tuinmachines/index.html'

Assert-NotContains $driveWinterHtml 'data-media-collection' 'driveshop/winteronderhoud-van-tuinmachines/index.html'
Assert-NotContains $driveWinterHtml 'media-collection' 'driveshop/winteronderhoud-van-tuinmachines/index.html'

if ($CssPath) {
    if (-not (Test-Path $CssPath)) {
        Add-Problem ('Missing CSS file: ' + $CssPath)
    }
    else {
        $css = Get-Content $CssPath -Raw
        foreach ($marker in @(
            '.site-brand__logo',
            '.site-nav__switch',
            '.site-nav__menu-toggle',
            '.site-nav__menu',
            '.site-nav__menu-shell',
            '.site-nav__menu-list[hidden]',
            '.site-nav__item,',
            '.home-hero__image',
            '.opening-hours',
            '.home-overview__panel',
            '.overview-card__media',
            '.overview-card__image',
            '.overview-card__overlay',
            '@font-face',
            '/fonts/Roboto-Regular.ttf',
            '/fonts/Roboto-Bold.ttf',
            'font-family: "Roboto", Arial, sans-serif;',
            '.media-collection',
            '.media-collection__filters',
            '.media-collection__filter',
            '.media-collection__grid--brand-links',
            '.media-collection__grid--hover-cards',
            '.media-collection__overlay',
            '.media-collection__title',
            'grid-template-columns: repeat(3, minmax(0, 1fr));',
            'aspect-ratio:',
            'object-fit: contain;'
        )) {
            if ($css -notmatch [regex]::Escape($marker)) {
                Add-Problem ('Missing CSS marker "' + $marker + '" in ' + $CssPath)
            }
        }
    }
}

if ($HeadTemplatePath) {
    if (-not (Test-Path $HeadTemplatePath)) {
        Add-Problem ('Missing head template: ' + $HeadTemplatePath)
    }
    else {
        $headTemplate = Get-Content $HeadTemplatePath -Raw
        Assert-Contains $headTemplate 'css/style.css' $HeadTemplatePath
    }
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'



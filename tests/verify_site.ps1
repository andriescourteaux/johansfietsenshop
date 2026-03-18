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
$bikeshopHtml = Read-Html 'bikeshop/index.html'
$driveshopHtml = Read-Html 'driveshop/index.html'
$bikeAccessoriesHtml = Read-Html 'bikeshop/accessoires/index.html'
$bikeModelsHtml = Read-Html 'bikeshop/modellen-in-de-kijker/index.html'
$bikeLeasingHtml = Read-Html 'bikeshop/leasing-fietsen/index.html'
$driveModelsHtml = Read-Html 'driveshop/modellen-in-de-kijker/index.html'
$driveWinterHtml = Read-Html 'driveshop/winteronderhoud-van-tuinmachines/index.html'

Assert-PathExists 'static/images/merken-verdelers/bikeshop' 'bike gallery source directory'
Assert-PathExists 'static/images/merken-verdelers/driveshop' 'drive gallery source directory'
Assert-PathExists 'data/merken-verdelers/bikeshop.toml' 'bike gallery metadata file'
Assert-PathExists 'data/merken-verdelers/driveshop.toml' 'drive gallery metadata file'

Assert-AllContains $homeHtml @(
    'home-hero',
    'home-hero__image',
    '/images/header_bike.webp',
    '/images/header_drive.webp',
    'data-shared-page="true"',
    'data-site-mode="bike"',
    'site-mode-script',
    'opening-hours',
    'Zondag en maandag gesloten',
    'Dinsdag tot zaterdag: 9u tot 17u',
    'Middagpauze voorzien',
    'data-mode-panel="bike"',
    'data-mode-panel="drive"',
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

Assert-NotContains $homeHtml 'Neem contact op voor vragen over winkels, producten of beschikbare merken.' 'index.html'
Assert-NotContains $homeHtml 'Ontdek onze focus op aandrijving, onderdelen en technische ondersteuning.' 'index.html'
Assert-NotContains $homeHtml 'Verken ons aanbod rond fietsen, accessoires en persoonlijk advies.' 'index.html'
Assert-NotContains $homeHtml 'site-nav__merken' 'index.html'

Assert-AllContains $contactHtml @(
    '<form',
    'Online verzending is nog niet actief.',
    'data-shared-page="true"',
    'data-site-mode="bike"',
    'site-mode-script',
    'site-nav__contact',
    'site-nav__switch'
) 'contact/index.html'

Assert-NotContains $contactHtml 'site-nav__merken' 'contact/index.html'

Assert-AllContains $bikeshopHtml @(
    'data-site-mode="bike"',
    'site-brand__logo',
    'site-nav__contact',
    'site-nav__switch'
) 'bikeshop/index.html'

Assert-NotContains $bikeshopHtml 'site-nav__merken' 'bikeshop/index.html'

Assert-AllContains $driveshopHtml @(
    'data-site-mode="drive"',
    'site-brand__logo',
    'site-nav__contact',
    'site-nav__switch'
) 'driveshop/index.html'

Assert-NotContains $driveshopHtml 'site-nav__merken' 'driveshop/index.html'

Assert-AllContains $bikeAccessoriesHtml @(
    'Accessoires',
    'data-site-mode="bike"'
) 'bikeshop/accessoires/index.html'

Assert-AllContains $bikeModelsHtml @(
    'Enkele modellen in de kijker',
    'data-site-mode="bike"'
) 'bikeshop/modellen-in-de-kijker/index.html'

Assert-AllContains $bikeLeasingHtml @(
    'Leasing fietsen',
    'data-site-mode="bike"'
) 'bikeshop/leasing-fietsen/index.html'

Assert-AllContains $driveModelsHtml @(
    'Modellen in de kijker',
    'data-site-mode="drive"'
) 'driveshop/modellen-in-de-kijker/index.html'

Assert-AllContains $driveWinterHtml @(
    'Winteronderhoud van tuinmachines',
    'data-site-mode="drive"'
) 'driveshop/winteronderhoud-van-tuinmachines/index.html'

Assert-AllContains $bikeMerkenHtml @(
    'merken-gallery',
    'data-merken-gallery',
    'merken-gallery__filters',
    'merken-gallery__filter',
    'data-merken-item',
    'data-tags=',
    'target="_blank"',
    'rel="noopener noreferrer"',
    'gazelle.png'
) 'bikeshop/merken-en-verdelers/index.html'

Assert-NotContains $bikeMerkenHtml 'merken-gallery__empty' 'bikeshop/merken-en-verdelers/index.html'
Assert-NotContains $bikeMerkenHtml 'brands-placeholder-grid' 'bikeshop/merken-en-verdelers/index.html'
Assert-NotContains $bikeMerkenHtml 'dealers-placeholder-grid' 'bikeshop/merken-en-verdelers/index.html'
Assert-NotContains $bikeMerkenHtml 'site-nav__merken' 'bikeshop/merken-en-verdelers/index.html'

Assert-AllContains $driveMerkenHtml @(
    'merken-gallery',
    'data-merken-gallery',
    'merken-gallery__filters',
    'merken-gallery__filter',
    'data-merken-item',
    'data-tags=',
    'target="_blank"',
    'rel="noopener noreferrer"',
    'gazelle.png'
) 'driveshop/merken-en-verdelers/index.html'

Assert-NotContains $driveMerkenHtml 'merken-gallery__empty' 'driveshop/merken-en-verdelers/index.html'
Assert-NotContains $driveMerkenHtml 'brands-placeholder-grid' 'driveshop/merken-en-verdelers/index.html'
Assert-NotContains $driveMerkenHtml 'dealers-placeholder-grid' 'driveshop/merken-en-verdelers/index.html'
Assert-NotContains $driveMerkenHtml 'site-nav__merken' 'driveshop/merken-en-verdelers/index.html'

if ($CssPath) {
    if (-not (Test-Path $CssPath)) {
        Add-Problem ('Missing CSS file: ' + $CssPath)
    }
    else {
        $css = Get-Content $CssPath -Raw
        foreach ($marker in @(
            '.site-brand__logo',
            '.site-nav__switch',
            '.home-hero__image',
            '@font-face',
            '/fonts/Roboto-Regular.ttf',
            '/fonts/Roboto-Bold.ttf',
            'font-family: "Roboto", Arial, sans-serif;',
            '.opening-hours',
            '.opening-hours__list',
            '.home-overview__panel',
            '.merken-gallery',
            '.merken-gallery__filters',
            '.merken-gallery__filter',
            '.merken-gallery__grid',
            'grid-template-columns: repeat(3, minmax(0, 1fr));',
            '.merken-gallery__media',
            '.merken-gallery__link',
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


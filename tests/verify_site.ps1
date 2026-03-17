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

$problems = @()

$homeHtml = Read-Html 'index.html'
$contactHtml = Read-Html 'contact/index.html'
$merkenHtml = Read-Html 'merken-en-verdelers/index.html'
$bikeMerkenHtml = Read-Html 'bikeshop/merken-en-verdelers/index.html'
$driveMerkenHtml = Read-Html 'driveshop/merken-en-verdelers/index.html'
$driveshopHtml = Read-Html 'driveshop/index.html'
$bikeshopHtml = Read-Html 'bikeshop/index.html'

Assert-Contains $homeHtml 'home-hero' 'index.html'
Assert-Contains $homeHtml 'home-hero__image' 'index.html'
Assert-Contains $homeHtml '/images/header_bike.jpg' 'index.html'
Assert-Contains $homeHtml '/images/header_drive.jpg' 'index.html'
Assert-Contains $homeHtml 'data-shared-page="true"' 'index.html'
Assert-Contains $homeHtml 'data-site-mode="bike"' 'index.html'
Assert-Contains $homeHtml 'site-mode-script' 'index.html'
Assert-Contains $homeHtml '?mode=bike' 'index.html'
Assert-Contains $homeHtml '?mode=drive' 'index.html'
Assert-Contains $homeHtml 'site-footer__link--contact' 'index.html'
Assert-Contains $homeHtml 'site-footer__link--merken' 'index.html'
Assert-Contains $contactHtml '<form' 'contact/index.html'
Assert-Contains $contactHtml 'Online verzending is nog niet actief.' 'contact/index.html'
Assert-Contains $contactHtml 'data-shared-page="true"' 'contact/index.html'
Assert-Contains $contactHtml 'data-site-mode="bike"' 'contact/index.html'
Assert-Contains $contactHtml 'site-mode-script' 'contact/index.html'
Assert-Contains $contactHtml 'site-footer__link--contact' 'contact/index.html'
Assert-Contains $contactHtml 'site-footer__link--merken' 'contact/index.html'
Assert-Contains $merkenHtml 'Merken in opbouw' 'merken-en-verdelers/index.html'
Assert-Contains $merkenHtml 'Verdelers in opbouw' 'merken-en-verdelers/index.html'
Assert-Contains $bikeMerkenHtml 'Bikeshop selectie' 'bikeshop/merken-en-verdelers/index.html'
Assert-Contains $driveMerkenHtml 'Driveshop selectie' 'driveshop/merken-en-verdelers/index.html'
Assert-Contains $driveshopHtml 'data-site-mode="drive"' 'driveshop/index.html'
Assert-Contains $driveshopHtml 'Neem contact op voor Driveshop' 'driveshop/index.html'
Assert-Contains $bikeshopHtml 'data-site-mode="bike"' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml 'Neem contact op voor Bikeshop' 'bikeshop/index.html'

Assert-Contains $bikeshopHtml 'site-brand__logo' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml '/images/logo.png' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml 'site-nav__home' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml 'site-nav__contact' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml 'site-nav__merken' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml '/bikeshop/merken-en-verdelers/' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml 'site-nav__switch' 'bikeshop/index.html'
Assert-Contains $bikeshopHtml '>Driveshop<' 'bikeshop/index.html'
Assert-NotContains $bikeshopHtml 'site-nav__switch">Bikeshop<' 'bikeshop/index.html'

Assert-Contains $driveshopHtml 'site-brand__logo' 'driveshop/index.html'
Assert-Contains $driveshopHtml '/images/logo-drive.png' 'driveshop/index.html'
Assert-Contains $driveshopHtml 'site-nav__home' 'driveshop/index.html'
Assert-Contains $driveshopHtml 'site-nav__contact' 'driveshop/index.html'
Assert-Contains $driveshopHtml 'site-nav__merken' 'driveshop/index.html'
Assert-Contains $driveshopHtml '/driveshop/merken-en-verdelers/' 'driveshop/index.html'
Assert-Contains $driveshopHtml 'site-nav__switch' 'driveshop/index.html'
Assert-Contains $driveshopHtml '>Bikeshop<' 'driveshop/index.html'
Assert-NotContains $driveshopHtml 'site-nav__switch">Driveshop<' 'driveshop/index.html'

if ($CssPath) {
    if (-not (Test-Path $CssPath)) {
        Add-Problem ('Missing CSS file: ' + $CssPath)
    }
    else {
        $css = Get-Content $CssPath -Raw
        foreach ($marker in @('.site-brand__logo', '.site-nav__switch', '.home-hero__image', '@media (max-width: 720px)', '@media (max-width: 640px)')) {
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

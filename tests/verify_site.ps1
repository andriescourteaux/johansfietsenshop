param(
    [Parameter(Mandatory = $true)]
    [string]$PublicDir,

    [string]$CssPath,

    [string]$HeadTemplatePath
)

$RepoRoot = Split-Path -Parent $PSScriptRoot
$problems = @()

function Add-Problem {
    param([string]$Message)
    $script:problems += $Message
}

function Read-GeneratedText {
    param([string]$RelativePath)

    $fullPath = Join-Path $PublicDir $RelativePath
    if (-not (Test-Path $fullPath)) {
        Add-Problem ('Missing generated file: ' + $RelativePath)
        return $null
    }

    return Get-Content $fullPath -Raw
}

function Read-RepoText {
    param([string]$RelativePath)

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        Add-Problem ('Missing repository file: ' + $RelativePath)
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

function Assert-Matches {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$Context
    )

    if ($null -eq $Content -or -not [regex]::IsMatch($Content, $Pattern)) {
        Add-Problem ('Missing pattern "' + $Pattern + '" in ' + $Context)
    }
}

function Assert-NotMatches {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$Context
    )

    if ($null -ne $Content -and [regex]::IsMatch($Content, $Pattern)) {
        Add-Problem ('Unexpected pattern "' + $Pattern + '" in ' + $Context)
    }
}

function Normalize-Text {
    param([string]$Content)

    if ($null -eq $Content) {
        return $null
    }

    $withoutTags = [regex]::Replace($Content, '<[^>]+>', ' ')
    $decoded = [System.Net.WebUtility]::HtmlDecode($withoutTags)
    return ([regex]::Replace($decoded, '\s+', ' ')).Trim()
}

function Assert-NormalizedContains {
    param(
        [string]$Content,
        [string]$ExpectedText,
        [string]$Context
    )

    if ($null -eq $Content) {
        Add-Problem ('Missing content for normalized text check in ' + $Context)
        return
    }

    if ([string]::IsNullOrWhiteSpace($ExpectedText)) {
        Add-Problem ('Missing expected normalized text for ' + $Context)
        return
    }

    $normalizedContent = Normalize-Text $Content
    $normalizedExpected = Normalize-Text $ExpectedText

    if (-not $normalizedContent.Contains($normalizedExpected)) {
        Add-Problem ('Missing authored text "' + $normalizedExpected + '" in ' + $Context)
    }
}

function Get-MarkdownBody {
    param([string]$RelativePath)

    $content = Read-RepoText $RelativePath
    if ($null -eq $content) {
        return $null
    }

    $match = [regex]::Match($content, '(?s)^\+\+\+.*?\+\+\+\s*(?<body>.+?)\s*$')
    if (-not $match.Success) {
        Add-Problem ('Unable to parse markdown body from ' + $RelativePath)
        return $null
    }

    return $match.Groups['body'].Value.Trim()
}

function Get-SectionFragment {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$Context
    )

    if ($null -eq $Content) {
        return $null
    }

    $match = [regex]::Match(
        $Content,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if (-not $match.Success) {
        Add-Problem ('Missing section pattern "' + $Pattern + '" in ' + $Context)
        return $null
    }

    return $match.Value
}

$homeHtml = Read-GeneratedText 'index.html'
$contactHtml = Read-GeneratedText 'contact/index.html'
$bikeLandingHtml = Read-GeneratedText 'bikeshop/index.html'
$driveLandingHtml = Read-GeneratedText 'driveshop/index.html'
$bikeBrandsHtml = Read-GeneratedText 'bikeshop/merken-en-verdelers/index.html'
$driveBrandsHtml = Read-GeneratedText 'driveshop/merken-en-verdelers/index.html'

$modeScriptTemplate = Read-RepoText 'layouts/partials/mode-script.html'
$singleTemplate = Read-RepoText 'layouts/_default/single.html'
$bikeBrandsData = Read-RepoText 'data/collecties/bikeshop/merken-en-verdelers.toml'
$driveBrandsData = Read-RepoText 'data/collecties/driveshop/merken-en-verdelers.toml'
$bikeBrandsContent = Read-RepoText 'content/merken-en-verdelers-bikeshop.md'
$driveBrandsContent = Read-RepoText 'content/merken-en-verdelers-driveshop.md'

$bikeLandingBody = Get-MarkdownBody 'content/bikeshop.md'
$driveLandingBody = Get-MarkdownBody 'content/driveshop.md'

$homeHeroSection = Get-SectionFragment $homeHtml '<section class="shared-hero.*?</section>' 'index.html'

# Issue 1: shared-page footer links must be drive-mode aware in the mode script.
Assert-Contains $homeHtml 'site-footer__link--contact' 'index.html'
Assert-Contains $homeHtml 'site-footer__link--merken' 'index.html'
Assert-Contains $contactHtml 'site-footer__link--contact' 'contact/index.html'
Assert-Contains $contactHtml 'site-footer__link--merken' 'contact/index.html'
Assert-Contains $modeScriptTemplate "applyHref('.site-footer__link--contact');" 'layouts/partials/mode-script.html'
Assert-Contains $modeScriptTemplate "applyHref('.site-footer__link--merken');" 'layouts/partials/mode-script.html'

# Issue 2: homepage hero copy must expose bike/drive text hooks for JS mode switching.
Assert-Contains $homeHeroSection 'page-copy--hero' 'index.html shared hero'
Assert-Matches $homeHeroSection '(?s)page-copy--hero[^>]*data-bike-[^=]+=' 'index.html shared hero'
Assert-Matches $homeHeroSection '(?s)page-copy--hero[^>]*data-drive-[^=]+=' 'index.html shared hero'
Assert-Contains $modeScriptTemplate 'page-copy--hero' 'layouts/partials/mode-script.html'

# Issue 3: section landing routes must render the authored section content.
Assert-NormalizedContains $bikeLandingHtml $bikeLandingBody 'bikeshop/index.html'
Assert-NormalizedContains $driveLandingHtml $driveLandingBody 'driveshop/index.html'

# Issue 4: brands migration must not depend on legacy gallery branches or paths, and BFK must not use Flanders.
Assert-NotContains $singleTemplate '.Params.gallery_mode' 'layouts/_default/single.html'
Assert-NotContains $singleTemplate 'partial "merken-gallery.html"' 'layouts/_default/single.html'
Assert-NotContains $singleTemplate 'partial "merken-gallery-script.html"' 'layouts/_default/single.html'
Assert-NotContains $bikeBrandsData '/images/merken-verdelers/' 'data/collecties/bikeshop/merken-en-verdelers.toml'
Assert-NotContains $driveBrandsData '/images/merken-verdelers/' 'data/collecties/driveshop/merken-en-verdelers.toml'
Assert-NotContains $bikeBrandsHtml '/images/merken-verdelers/' 'bikeshop/merken-en-verdelers/index.html'
Assert-NotContains $driveBrandsHtml '/images/merken-verdelers/' 'driveshop/merken-en-verdelers/index.html'
Assert-Contains $bikeBrandsHtml 'aria-label="BFK"' 'bikeshop/merken-en-verdelers/index.html'
Assert-NotMatches $bikeBrandsHtml '<a[^>]+href="https://flandersfietsen\.be/wp/"[^>]+aria-label="BFK"' 'bikeshop/merken-en-verdelers/index.html'

# Issue 5: active brands content must not keep dead legacy front matter keys.
foreach ($contentCheck in @(
    @{ Content = $bikeBrandsContent; Context = 'content/merken-en-verdelers-bikeshop.md' },
    @{ Content = $driveBrandsContent; Context = 'content/merken-en-verdelers-driveshop.md' }
)) {
    Assert-NotMatches $contentCheck.Content '(?m)^gallery_mode\s*=' $contentCheck.Context
    Assert-NotMatches $contentCheck.Content '(?m)^gallery_data_key\s*=' $contentCheck.Context
    Assert-NotMatches $contentCheck.Content '(?m)^brands_heading\s*=' $contentCheck.Context
    Assert-NotMatches $contentCheck.Content '(?m)^dealers_heading\s*=' $contentCheck.Context
    Assert-NotMatches $contentCheck.Content '(?m)^brands\s*=' $contentCheck.Context
    Assert-NotMatches $contentCheck.Content '(?m)^dealers\s*=' $contentCheck.Context
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'

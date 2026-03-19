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

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        Add-Problem $Message
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

function Get-FrontMatter {
    param([string]$RelativePath)

    $content = Read-RepoText $RelativePath
    if ([string]::IsNullOrWhiteSpace($content)) {
        return $null
    }

    $match = [regex]::Match($content, '(?s)\A\+\+\+\s*(?<frontMatter>.*?)\s*\+\+\+')
    if (-not $match.Success) {
        Add-Problem ('Missing TOML front matter in ' + $RelativePath)
        return $null
    }

    return $match.Groups['frontMatter'].Value
}

function Get-TomlStringArray {
    param(
        [string]$Content,
        [string]$Key,
        [string]$Context
    )

    if ($null -eq $Content) {
        return @()
    }

    $pattern = '(?s)^\s*' + [regex]::Escape($Key) + '\s*=\s*\[(?<body>.*?)\]'
    $match = [regex]::Match($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $match.Success) {
        Add-Problem ('Missing TOML array key "' + $Key + '" in ' + $Context)
        return @()
    }

    $values = @()
    foreach ($entryMatch in [regex]::Matches($match.Groups['body'].Value, '["''](?<value>[^"'']+)["'']')) {
        $values += $entryMatch.Groups['value'].Value.Trim()
    }

    if ($values.Count -eq 0) {
        Add-Problem ('Missing TOML array values for "' + $Key + '" in ' + $Context)
    }

    return $values
}

function Get-OpeningHoursPairs {
    param(
        [string[]]$Lines,
        [string]$Context
    )

    $pairs = @()
    foreach ($line in $Lines) {
        $parts = $line -split ':\s*', 2
        if ($parts.Count -ne 2) {
            Add-Problem ('Unable to parse opening hours line "' + $line + '" in ' + $Context)
            continue
        }

        $pairs += @{
            Day = $parts[0].Trim()
            Value = $parts[1].Trim()
        }
    }

    return $pairs
}

$homeHtml = Read-GeneratedText 'index.html'
$contactHtml = Read-GeneratedText 'contact/index.html'
$bikeLandingHtml = Read-GeneratedText 'bikeshop/index.html'
$driveLandingHtml = Read-GeneratedText 'driveshop/index.html'
$bikeBrandsHtml = Read-GeneratedText 'bikeshop/merken-en-verdelers/index.html'
$driveBrandsHtml = Read-GeneratedText 'driveshop/merken-en-verdelers/index.html'

$modeScriptTemplate = Read-RepoText 'layouts/partials/mode-script.html'
$sharedHeroTemplate = Read-RepoText 'layouts/partials/shared-hero.html'
$singleTemplate = Read-RepoText 'layouts/_default/single.html'
$bikeBrandsData = Read-RepoText 'data/collecties/bikeshop/merken-en-verdelers.toml'
$driveBrandsData = Read-RepoText 'data/collecties/driveshop/merken-en-verdelers.toml'
$bikeBrandsContent = Read-RepoText 'content/merken-en-verdelers-bikeshop.md'
$driveBrandsContent = Read-RepoText 'content/merken-en-verdelers-driveshop.md'
$homeFrontMatter = Get-FrontMatter 'content/_index.md'
$cssContent = if ([string]::IsNullOrWhiteSpace($CssPath)) { $null } else { Read-RepoText $CssPath }
$motionHookContent = @($modeScriptTemplate, $cssContent) -join "`n"

$bikeLandingBody = Get-MarkdownBody 'content/bikeshop.md'
$driveLandingBody = Get-MarkdownBody 'content/driveshop.md'
$homeOpeningHours = Get-TomlStringArray $homeFrontMatter 'opening_hours' 'content/_index.md front matter'
$homeOpeningHoursPairs = Get-OpeningHoursPairs $homeOpeningHours 'content/_index.md'

$homeHeaderSection = Get-SectionFragment $homeHtml '<header\b[^>]*class="[^"]*\bsite-header\b[^"]*"[^>]*>.*?</header>' 'index.html header'
$homeHeroSection = Get-SectionFragment $homeHtml '<section\b[^>]*class="[^"]*\bshared-hero\b[^"]*"[^>]*>.*?</section>' 'index.html'
$homeOverviewSection = Get-SectionFragment $homeHtml '<section\b[^>]*class="[^"]*\bhome-overview\b[^"]*"[^>]*>.*?</section>' 'index.html home overview'
$homeFooterSection = Get-SectionFragment $homeHtml '<footer\b[^>]*class="[^"]*\bsite-footer\b[^"]*"[^>]*>.*?</footer>' 'index.html footer'

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

# Issue 6: homepage hours move below the cards, footer repeats them as plain text, cards use webp, and header toggle typography is centralized.
Assert-NotMatches $homeHeroSection '(?is)<(?:div|section)[^>]*class="[^"]*\bopening-hours\b[^"]*"' 'index.html shared hero'

$afterHomeOverview = $null
if ($null -ne $homeHtml -and $null -ne $homeOverviewSection) {
    $homeOverviewIndex = $homeHtml.IndexOf($homeOverviewSection)
    if ($homeOverviewIndex -ge 0) {
        $afterHomeOverview = $homeHtml.Substring($homeOverviewIndex + $homeOverviewSection.Length)
    }
}

Assert-True ($null -ne $afterHomeOverview) 'Unable to locate content after the home cards in index.html'

$openingHoursTableSection = Get-SectionFragment `
    $afterHomeOverview `
    '(?is)<section\b[^>]*>.*?<table\b[^>]*>.*?</table>.*?</section>' `
    'index.html after home cards'

if ($null -ne $openingHoursTableSection) {
    foreach ($hoursPair in $homeOpeningHoursPairs) {
        Assert-Matches `
            $openingHoursTableSection `
            ('(?is)<tr\b[^>]*>.*?' + [regex]::Escape($hoursPair.Day) + '.*?' + [regex]::Escape($hoursPair.Value) + '.*?</tr>') `
            'index.html opening-hours table rows'
    }
}

foreach ($hoursLine in $homeOpeningHours) {
    Assert-NormalizedContains $homeFooterSection $hoursLine 'index.html footer'
}

$overviewCardImageTags = @([regex]::Matches($homeHtml, '<img\b[^>]*\bclass="[^"]*\boverview-card__image\b[^"]*"[^>]*>'))
if ($overviewCardImageTags.Count -eq 0) {
    Add-Problem 'Missing homepage overview card images in index.html'
}
else {
    foreach ($imageTag in $overviewCardImageTags) {
        $srcMatch = [regex]::Match($imageTag.Value, '\bsrc="(?<src>[^"]+)"')
        if (-not $srcMatch.Success) {
            Add-Problem ('Missing homepage overview card image src in index.html tag: ' + $imageTag.Value)
            continue
        }

        $imageSrc = $srcMatch.Groups['src'].Value
        if ($imageSrc -notmatch '\.webp(?:[?#].*)?$') {
            Add-Problem ('Homepage card image must use webp: ' + $imageSrc)
        }
    }
}

Assert-True (-not [string]::IsNullOrWhiteSpace($CssPath)) 'Missing -CssPath for homepage issue 6 CSS checks'
Assert-True ($null -ne $cssContent) ('Unable to read CSS content from ' + $CssPath)
Assert-NotMatches `
    $cssContent `
    '(?is)\.site-header--overlay\b[^{}]*\.site-nav__(?:menu-toggle|menu-label)\b[^{}]*\{[^}]*\b(?:font|font-size|font-family|font-variant|text-transform)\s*:' `
    'assets/css/style.css overlay menu typography override'

# Issue 7: motion/theme polish hooks must exist for the mode pill, footer themes, menu motion, parallax, and reduced-motion handling.
Assert-Contains $homeHeaderSection 'site-nav__mode-toggle' 'index.html header'
Assert-Contains $homeHeaderSection 'site-nav__mode-track' 'index.html header'
Assert-Contains $homeHeaderSection 'site-nav__mode-thumb' 'index.html header'
Assert-Contains $homeHeaderSection 'site-nav__mode-text' 'index.html header'
Assert-Matches `
    $cssContent `
    '(?is)(?:\.site-footer--bike|\[data-site-mode=["'']bike["'']\][^{]*\.site-footer|\.site-footer[^{]*data-[^=]+=["'']bike["''])' `
    'assets/css/style.css bike footer theme hook'
Assert-Matches `
    $cssContent `
    '(?is)(?:\.site-footer--drive|\[data-site-mode=["'']drive["'']\][^{]*\.site-footer|\.site-footer[^{]*data-[^=]+=["'']drive["''])' `
    'assets/css/style.css drive footer theme hook'
# Accept either dedicated menu motion classes/data hooks or transition rules on the menu container.
Assert-Matches `
    $motionHookContent `
    '(?is)(?:site-nav__menu--[a-z0-9-]*(?:open|clos|enter|exit|motion|animat|transition)[a-z0-9-]*|data-(?:menu|nav)-(?:state|motion|transition)\s*=|\.site-nav__menu(?:-panel)?[^{]*\{[^}]*\b(?:transition|animation)\s*:)' `
    'menu animation hooks'
Assert-Matches `
    $sharedHeroTemplate `
    '(?is)(?:data-parallax-[^=]+=|data-hero-parallax=|home-hero__image--parallax)' `
    'layouts/partials/shared-hero.html'
Assert-Matches `
    $cssContent `
    '@media\s*\(\s*prefers-reduced-motion\s*:\s*reduce\s*\)' `
    'assets/css/style.css reduced motion branch'

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'

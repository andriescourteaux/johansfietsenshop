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

function Get-CssRules {
    param([string]$CssContent)

    if ([string]::IsNullOrWhiteSpace($CssContent)) {
        return @()
    }

    $rules = @()
    $pattern = '(?is)(?<selector>[^{}]+?)\s*\{(?<body>[^{}]*)\}'
    foreach ($match in [regex]::Matches($CssContent, $pattern)) {
        $selector = $match.Groups['selector'].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($selector) -or $selector.TrimStart().StartsWith('@')) {
            continue
        }

        $rules += [pscustomobject]@{
            Selector = $selector
            Body = $match.Groups['body'].Value
        }
    }

    return $rules
}

function Get-CssVariableReferences {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return @()
    }

    $variableNames = @()
    foreach ($match in [regex]::Matches($CssBody, '(?is)var\(\s*(--[a-z0-9-]+)')) {
        $variableNames += $match.Groups[1].Value
    }

    return @($variableNames | Sort-Object -Unique)
}

function Get-CssVariableAssignments {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return @()
    }

    $variableNames = @()
    foreach ($match in [regex]::Matches($CssBody, '(?is)(--[a-z0-9-]+)\s*:')) {
        $variableNames += $match.Groups[1].Value
    }

    return @($variableNames | Sort-Object -Unique)
}

function Test-IsModeScopedSelector {
    param(
        [string]$Selector,
        [string]$Mode
    )

    if ([string]::IsNullOrWhiteSpace($Selector) -or [string]::IsNullOrWhiteSpace($Mode)) {
        return $false
    }

    $escapedMode = [regex]::Escape($Mode)
    $modeSelectorPattern = '(?is)(?:' +
        '[#.][a-z0-9_-]*' + $escapedMode + '[a-z0-9_-]*|' +
        '\[(?:data-[^]=]+|class|id)[^]]*=\s*(?:["''][^"'']*' + $escapedMode + '[^"'']*["'']|[a-z0-9_-]*' + $escapedMode + '[a-z0-9_-]*)[^]]*\]' +
        ')'
    return [regex]::IsMatch($Selector, $modeSelectorPattern)
}

function Test-IsFooterSelector {
    param([string]$Selector)

    if ([string]::IsNullOrWhiteSpace($Selector)) {
        return $false
    }

    return [regex]::IsMatch($Selector, '(?i)\.site-footer(?:\b|__)')
}

function Test-IsFooterContainerSelector {
    param([string]$Selector)

    if ([string]::IsNullOrWhiteSpace($Selector)) {
        return $false
    }

    return [regex]::IsMatch($Selector, '(?i)\.site-footer\b')
}

function Test-IsDedicatedFooterVariable {
    param([string]$VariableName)

    if ([string]::IsNullOrWhiteSpace($VariableName)) {
        return $false
    }

    return [regex]::IsMatch($VariableName, '(?i)^--[a-z0-9-]*footer[a-z0-9-]*$')
}

function Test-RuleHasThemeDeclarations {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return $false
    }

    return [regex]::IsMatch($CssBody, '(?is)\b(?:background|background-color|color|border|border-color)\s*:') -or
        [regex]::IsMatch($CssBody, '(?is)--[a-z0-9-]+\s*:')
}

function Test-ModeAwareFooterTheme {
    param(
        [string]$CssContent,
        [string]$Mode
    )

    if ([string]::IsNullOrWhiteSpace($CssContent) -or [string]::IsNullOrWhiteSpace($Mode)) {
        return $false
    }

    $cssRules = Get-CssRules $CssContent
    if ($cssRules.Count -eq 0) {
        return $false
    }

    $footerContainerRules = @($cssRules | Where-Object { Test-IsFooterContainerSelector $_.Selector })
    $footerRules = @($cssRules | Where-Object { Test-IsFooterSelector $_.Selector })
    if ($footerContainerRules.Count -eq 0 -and $footerRules.Count -eq 0) {
        return $false
    }

    $dedicatedFooterThemeVariables = @(
        $footerRules |
            ForEach-Object { Get-CssVariableReferences $_.Body } |
            Where-Object { Test-IsDedicatedFooterVariable $_ } |
            Sort-Object -Unique
    )

    foreach ($rule in $cssRules) {
        if (-not (Test-IsModeScopedSelector $rule.Selector $Mode)) {
            continue
        }

        if ((Test-IsFooterContainerSelector $rule.Selector) -and (Test-RuleHasThemeDeclarations $rule.Body)) {
            return $true
        }

        if ($dedicatedFooterThemeVariables.Count -eq 0) {
            continue
        }

        $assignedVariables = Get-CssVariableAssignments $rule.Body
        if (@(
                $assignedVariables |
                    Where-Object {
                        (Test-IsDedicatedFooterVariable $_) -and
                        ($dedicatedFooterThemeVariables -contains $_)
                    }
            ).Count -gt 0) {
            return $true
        }
    }

    return $false
}

function Test-IsMenuSelector {
    param([string]$Selector)

    if ([string]::IsNullOrWhiteSpace($Selector)) {
        return $false
    }

    return [regex]::IsMatch($Selector, '(?i)\.site-nav__menu(?:-panel)?\b')
}

function Test-IsStatefulMenuSelector {
    param([string]$Selector)

    if (-not (Test-IsMenuSelector $Selector)) {
        return $false
    }

    $statePattern = '(?is)(?:' +
        '\[(?:aria-expanded|aria-hidden|hidden)\b|' +
        '\[data-[^]]*(?:menu|nav|state|motion|open|expanded)[^]]*=' +
        '|[#.][a-z0-9_-]*(?:is-|has-)?(?:open|opened|opening|close|closed|closing|active|expanded|visible|hidden|enter|exit)[a-z0-9_-]*' +
        '|:(?:not\(\[hidden\]\)|is\(:not\(\[hidden\]\)\))' +
        ')'
    return [regex]::IsMatch($Selector, $statePattern)
}

function Test-RuleHasMenuMotionProperties {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return $false
    }

    return [regex]::IsMatch($CssBody, '(?is)\b(?:opacity|transform|translate|scale|rotate)\s*:')
}

function Test-RuleHasMenuMotionTransition {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return $false
    }

    return [regex]::IsMatch($CssBody, '(?is)\btransition\s*:\s*[^;{}]*(?:all|opacity|transform|translate|scale|rotate)') -or
        [regex]::IsMatch($CssBody, '(?is)\btransition-property\s*:\s*[^;{}]*(?:all|opacity|transform|translate|scale|rotate)') -or
        [regex]::IsMatch($CssBody, '(?is)\banimation(?:-name)?\s*:')
}

function Get-MenuStateKinds {
    param([string]$Selector)

    if ([string]::IsNullOrWhiteSpace($Selector)) {
        return @()
    }

    $stateKinds = @()

    if ([regex]::IsMatch($Selector, '(?is)\[hidden\b') -or
        [regex]::IsMatch($Selector, '(?is)\[aria-expanded\s*=\s*["'']?false["'']?\]') -or
        [regex]::IsMatch($Selector, '(?is)\[aria-hidden\s*=\s*["'']?true["'']?\]') -or
        [regex]::IsMatch($Selector, '(?is)\[data-[^]=]+=\s*["'']?(?:closed|closing|hidden|collapsed|exit)["'']?\]') -or
        [regex]::IsMatch($Selector, '(?is)[#.][a-z0-9_-]*(?:is-|has-)?(?:close|closed|closing|hidden|collapsed|exit)[a-z0-9_-]*')) {
        $stateKinds += 'closed'
    }

    if ([regex]::IsMatch($Selector, '(?is):(?:not\(\[hidden\]\)|is\(:not\(\[hidden\]\)\))') -or
        [regex]::IsMatch($Selector, '(?is)\[aria-expanded\s*=\s*["'']?true["'']?\]') -or
        [regex]::IsMatch($Selector, '(?is)\[aria-hidden\s*=\s*["'']?false["'']?\]') -or
        [regex]::IsMatch($Selector, '(?is)\[data-[^]=]+=\s*["'']?(?:open|opened|opening|expanded|visible|active)["'']?\]') -or
        [regex]::IsMatch($Selector, '(?is)[#.][a-z0-9_-]*(?:is-|has-)?(?:open|opened|opening|expanded|visible|active)[a-z0-9_-]*')) {
        $stateKinds += 'open'
    }

    return @($stateKinds | Sort-Object -Unique)
}

function Test-MenuRulesAreComplementary {
    param(
        [pscustomobject]$PrimaryRule,
        [pscustomobject]$SecondaryRule
    )

    if ($null -eq $PrimaryRule -or $null -eq $SecondaryRule) {
        return $false
    }

    if ($PrimaryRule.Selector -eq $SecondaryRule.Selector) {
        return $false
    }

    if (-not $SecondaryRule.IsStateful) {
        return $true
    }

    $primaryStates = @($PrimaryRule.StateKinds)
    $secondaryStates = @($SecondaryRule.StateKinds)
    if ($primaryStates.Count -eq 0 -or $secondaryStates.Count -eq 0) {
        return $false
    }

    return (
        (@($primaryStates | Where-Object { $_ -eq 'open' }).Count -gt 0 -and
            @($secondaryStates | Where-Object { $_ -eq 'closed' }).Count -gt 0) -or
        (@($primaryStates | Where-Object { $_ -eq 'closed' }).Count -gt 0 -and
            @($secondaryStates | Where-Object { $_ -eq 'open' }).Count -gt 0)
    )
}

function Test-HasStatefulMenuMotion {
    param([string]$CssContent)

    if ([string]::IsNullOrWhiteSpace($CssContent)) {
        return $false
    }

    $menuMotionRules = @(
        foreach ($rule in (Get-CssRules $CssContent)) {
            if (-not (Test-IsMenuSelector $rule.Selector)) {
                continue
            }

            [pscustomobject]@{
                Selector = $rule.Selector
                IsStateful = Test-IsStatefulMenuSelector $rule.Selector
                HasMotionProperties = Test-RuleHasMenuMotionProperties $rule.Body
                HasMotionTransition = Test-RuleHasMenuMotionTransition $rule.Body
                StateKinds = @(Get-MenuStateKinds $rule.Selector)
            }
        }
    )

    $statefulMotionRules = @(
        $menuMotionRules |
            Where-Object { $_.IsStateful -and $_.HasMotionProperties }
    )
    if ($statefulMotionRules.Count -eq 0) {
        return $false
    }

    foreach ($statefulRule in $statefulMotionRules) {
        foreach ($otherRule in $menuMotionRules) {
            if (-not $otherRule.HasMotionProperties) {
                continue
            }

            if (-not (Test-MenuRulesAreComplementary $statefulRule $otherRule)) {
                continue
            }

            if ($statefulRule.HasMotionTransition -or $otherRule.HasMotionTransition) {
                return $true
            }
        }
    }

    return $false
}

function Assert-StatefulMenuMotion {
    param(
        [string]$CssContent,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($CssContent)) {
        Add-Problem ('Missing content for ' + $Context)
        return
    }

    if (-not (Test-HasStatefulMenuMotion $CssContent)) {
        Add-Problem ('Missing stateful menu open/close motion hook in ' + $Context)
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

$footerThemeVariableFixture = @'
.site-footer {
    background: var(--footer-bg);
    color: var(--footer-text);
}

body[data-theme="bike"] .site-footer {
    --footer-bg: #103423;
    --footer-text: #f5f2e8;
}
'@
Assert-True `
    (Test-ModeAwareFooterTheme $footerThemeVariableFixture 'bike') `
    'Verifier must accept footer theme hooks delivered through mode-scoped footer container variables'

$genericFooterThemeLeakFixture = @'
.site-footer__link {
    color: var(--link-color);
}

body[data-theme="bike"] {
    --link-color: blue;
}
'@
Assert-True `
    (-not (Test-ModeAwareFooterTheme $genericFooterThemeLeakFixture 'bike')) `
    'Verifier must reject generic descendant variables that are not dedicated footer theme hooks'

$dedicatedFooterThemeVariableFixture = @'
.site-footer {
    background: var(--footer-background);
    color: var(--footer-foreground);
}

body[data-theme="bike"] {
    --footer-background: #103423;
    --footer-foreground: #f5f2e8;
}
'@
Assert-True `
    (Test-ModeAwareFooterTheme $dedicatedFooterThemeVariableFixture 'bike') `
    'Verifier must accept dedicated footer theme variables scoped outside the footer container'

$statefulMenuMotionFixture = @'
.site-nav__menu-panel {
    opacity: 0;
    transform: translateY(-0.5rem);
    transition: opacity 180ms ease, transform 180ms ease;
}

.site-nav__menu-shell.is-open .site-nav__menu-panel {
    opacity: 1;
    transform: translateY(0);
}
'@
Assert-True `
    (Test-HasStatefulMenuMotion $statefulMenuMotionFixture) `
    'Verifier must accept stateful menu motion selectors that drive opacity or transform'

$weakMenuMotionFixture = @'
.site-nav__menu-panel {
    transition: opacity 180ms ease;
}

.site-nav__menu-shell[data-menu-state="open"] .site-nav__menu-panel {
    display: block;
}
'@
Assert-True `
    (-not (Test-HasStatefulMenuMotion $weakMenuMotionFixture)) `
    'Verifier must reject generic menu transitions without stateful motion properties'

$singleStateMenuMotionFixture = @'
.site-nav__menu[hidden] {
    opacity: 0;
}
'@
Assert-True `
    (-not (Test-HasStatefulMenuMotion $singleStateMenuMotionFixture)) `
    'Verifier must reject single-state menu motion rules without open and close behavior'

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
Assert-True `
    (Test-ModeAwareFooterTheme $cssContent 'bike') `
    'Missing mode-aware bike footer theme hook in assets/css/style.css'
Assert-True `
    (Test-ModeAwareFooterTheme $cssContent 'drive') `
    'Missing mode-aware drive footer theme hook in assets/css/style.css'
Assert-StatefulMenuMotion `
    $cssContent `
    'assets/css/style.css menu motion hooks'
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

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

    $explicitModeTokenPattern = '(?i)(?:^|[^a-z0-9])' + [regex]::Escape($Mode) + '(?:[^a-z0-9]|$)'

    foreach ($tokenMatch in [regex]::Matches($Selector, '(?i)[#.](?<token>[a-z0-9_-]+)')) {
        $token = $tokenMatch.Groups['token'].Value
        if ([regex]::IsMatch($token, '(?i)(?:theme|mode)') -and
            [regex]::IsMatch($token, $explicitModeTokenPattern)) {
            return $true
        }
    }

    foreach ($attributeMatch in [regex]::Matches($Selector, '(?is)\[(?<name>[a-z0-9_-]+)\s*(?:[~|^$*]?=)\s*(?<value>"[^"]*"|''[^'']*''|[^\]\s]+)[^\]]*\]')) {
        $attributeName = $attributeMatch.Groups['name'].Value
        $attributeValue = $attributeMatch.Groups['value'].Value.Trim('"', "'").Trim()

        if ([string]::IsNullOrWhiteSpace($attributeValue)) {
            continue
        }

        if ([regex]::IsMatch($attributeName, '(?i)(?:theme|mode)') -and
            [regex]::IsMatch($attributeValue, $explicitModeTokenPattern)) {
            return $true
        }

        if ($attributeName -imatch '^(?:class|id)$') {
            foreach ($attributeToken in ($attributeValue -split '\s+')) {
                if ([regex]::IsMatch($attributeToken, '(?i)(?:theme|mode)') -and
                    [regex]::IsMatch($attributeToken, $explicitModeTokenPattern)) {
                    return $true
                }
            }
        }
    }

    return $false
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

    return [regex]::IsMatch($VariableName, '(?i)^--(?:site-)?footer-[a-z0-9-]+$')
}

function Test-RuleHasFooterThemeDeclarations {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return $false
    }

    return [regex]::IsMatch($CssBody, '(?im)(?:^|[;\r\n]\s*)(?:background|background-color|color|border|border-color)\s*:') -or
        @(
            Get-CssVariableAssignments $CssBody |
                Where-Object { Test-IsDedicatedFooterVariable $_ }
        ).Count -gt 0
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

        if ((Test-IsFooterContainerSelector $rule.Selector) -and (Test-RuleHasFooterThemeDeclarations $rule.Body)) {
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

    return [regex]::IsMatch($Selector, '(?i)\.(?:site-nav__menu|site-nav__menu-panel)(?![-a-z0-9_])')
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

function Get-MenuTargetKinds {
    param([string]$Selector)

    if ([string]::IsNullOrWhiteSpace($Selector)) {
        return @()
    }

    $targetKinds = @()

    if ([regex]::IsMatch($Selector, '(?i)\.site-nav__menu(?![-a-z0-9_])')) {
        $targetKinds += 'menu'
    }

    if ([regex]::IsMatch($Selector, '(?i)\.site-nav__menu-panel(?![-a-z0-9_])')) {
        $targetKinds += 'panel'
    }

    return @($targetKinds | Sort-Object -Unique)
}

function Get-MenuMotionPropertyNames {
    param([string]$CssBody)

    if ([string]::IsNullOrWhiteSpace($CssBody)) {
        return @()
    }

    $propertyNames = @()
    foreach ($match in [regex]::Matches($CssBody, '(?im)^\s*(opacity|transform|translate|scale|rotate)\s*:')) {
        $propertyNames += $match.Groups[1].Value.ToLowerInvariant()
    }

    return @($propertyNames | Sort-Object -Unique)
}

function Test-MenuRulesShareTargets {
    param(
        [pscustomobject]$PrimaryRule,
        [pscustomobject]$SecondaryRule
    )

    if ($null -eq $PrimaryRule -or $null -eq $SecondaryRule) {
        return $false
    }

    return @(
        @($PrimaryRule.TargetKinds) |
            Where-Object { @($SecondaryRule.TargetKinds) -contains $_ }
    ).Count -gt 0
}

function Test-MenuRulesShareMotionProperties {
    param(
        [pscustomobject]$PrimaryRule,
        [pscustomobject]$SecondaryRule
    )

    if ($null -eq $PrimaryRule -or $null -eq $SecondaryRule) {
        return $false
    }

    return @(
        @($PrimaryRule.MotionProperties) |
            Where-Object { @($SecondaryRule.MotionProperties) -contains $_ }
    ).Count -gt 0
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

    if (-not (Test-MenuRulesShareTargets $PrimaryRule $SecondaryRule)) {
        return $false
    }

    if (-not (Test-MenuRulesShareMotionProperties $PrimaryRule $SecondaryRule)) {
        return $false
    }

    if ($PrimaryRule.IsStateful -and $SecondaryRule.IsStateful) {
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

    if ($PrimaryRule.IsStateful -xor $SecondaryRule.IsStateful) {
        $statefulRule = if ($PrimaryRule.IsStateful) { $PrimaryRule } else { $SecondaryRule }
        return @($statefulRule.StateKinds).Count -gt 0
    }

    return $false
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
                TargetKinds = @(Get-MenuTargetKinds $rule.Selector)
                MotionProperties = @(Get-MenuMotionPropertyNames $rule.Body)
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

$incidentalDriveSubstringFixture = @'
.site-footer {
    background: var(--footer-bg);
}

.driveway .site-footer {
    --footer-bg: red;
}
'@
Assert-True `
    (-not (Test-ModeAwareFooterTheme $incidentalDriveSubstringFixture 'drive')) `
    'Verifier must reject incidental mode substrings like .driveway when checking footer theme scope'

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

$footerContainerGenericVariableFixture = @'
.site-footer {
    color: var(--link-color);
}

body[data-theme="bike"] .site-footer {
    --link-color: blue;
}
'@
Assert-True `
    (-not (Test-ModeAwareFooterTheme $footerContainerGenericVariableFixture 'bike')) `
    'Verifier must reject generic variables on the footer container when they are not footer-dedicated theme hooks'

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

$menuIconMotionFixture = @'
.site-nav__menu-icon {
    transform: rotate(0deg);
    transition: transform 180ms ease;
}

.site-nav__menu-icon.is-open {
    transform: rotate(90deg);
}
'@
Assert-True `
    (-not (Test-HasStatefulMenuMotion $menuIconMotionFixture)) `
    'Verifier must ignore menu icon motion selectors when checking for menu panel motion hooks'

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

$weakBaseStateMenuMotionFixture = @'
.site-nav__menu-panel {
    opacity: 0;
    transition: opacity 180ms ease;
}

.site-nav__menu-shell[data-menu-state="open"] .site-nav__menu-panel {
    transform: translateY(0);
}
'@
Assert-True `
    (-not (Test-HasStatefulMenuMotion $weakBaseStateMenuMotionFixture)) `
    'Verifier must reject weak base-plus-state menu motion pairs that do not animate the same property'

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
    foreach ($hoursLine in $homeOpeningHours) {
        $serialized = [regex]::Replace($hoursLine, '^([^:]+):\s*(.*)$', '$1||$2')
        $parts = $serialized -split '\|\|', 2
        $day = $parts[0]
        $slots = @($parts[1] -split '\s*\|\s*' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $rowPattern = '(?is)<tr\b[^>]*>.*?' + [regex]::Escape($day)

        if ($slots.Count -gt 0) {
            $rowPattern += '.*?' + (($slots | ForEach-Object { [regex]::Escape($_) }) -join '.*?')
        }

        $rowPattern += '.*?</tr>'
        Assert-Matches $openingHoursTableSection $rowPattern 'index.html opening-hours table rows'

        $footerPattern = '(?is)' + [regex]::Escape($day)
        if ($slots.Count -gt 0) {
            $footerPattern += '.*?' + (($slots | ForEach-Object { [regex]::Escape($_) }) -join '.*?')
        }

        Assert-Matches $homeFooterSection $footerPattern 'index.html footer'
    }
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

# Issue 8: hero eyebrow removed, contact stays inside the dropdown, the home table splits midday slots, and the contact page exposes the expected hooks.
Assert-NotContains $sharedHeroTemplate 'Site2' 'layouts/partials/shared-hero.html'
Assert-NotContains $homeHeroSection 'Site2' 'index.html shared hero'
Assert-NotContains $homeHeaderSection 'site-nav__contact' 'index.html header'
Assert-NotContains $modeScriptTemplate "applyHref('.site-nav__contact');" 'layouts/partials/mode-script.html'
Assert-Matches `
    $homeHeaderSection `
    '(?is)<ul\b[^>]*data-mode-nav="bike"[^>]*>.*?>Contact<' `
    'index.html bike header menu'
Assert-Matches `
    $homeHeaderSection `
    '(?is)<ul\b[^>]*data-mode-nav="drive"[^>]*>.*?>Contact<' `
    'index.html drive header menu'
Assert-Matches `
    $modeScriptTemplate `
    "(?s)const openMenu = \(\) => \{.*?menu\.hidden = false;.*?applyMenuState\('closed'\);.*?requestAnimationFrame\(\(\) => \{.*?applyMenuState\('opening'\);" `
    'layouts/partials/mode-script.html menu opening animation hook'

Assert-NotContains $openingHoursTableSection '|' 'index.html opening-hours table'
Assert-Contains $homeFooterSection '|' 'index.html footer opening hours'

foreach ($hoursLine in @($homeOpeningHours | Where-Object { $_ -match '\|' })) {
    $serialized = [regex]::Replace($hoursLine, '^([^:]+):\s*(.*)$', '$1||$2')
    $parts = $serialized -split '\|\|', 2
    $day = $parts[0]
    $slots = @($parts[1] -split '\s*\|\s*' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    Assert-NotContains $openingHoursTableSection $hoursLine 'index.html opening-hours table'
    Assert-NormalizedContains $homeFooterSection $hoursLine 'index.html footer opening hours'

    if ($slots.Count -gt 0) {
        Assert-Matches `
            $openingHoursTableSection `
            ('(?is)<tr\b[^>]*>.*?' + [regex]::Escape($day) + '.*?' + (($slots | ForEach-Object { [regex]::Escape($_) }) -join '.*?') + '.*?</tr>') `
            'index.html split opening-hours table row'
    }
}

Assert-Matches $contactHtml '(?is)\bcontact-panel__name\b' 'contact/index.html'
Assert-Matches $contactHtml '(?is)\bcontact-panel__term\b' 'contact/index.html'
Assert-Matches $contactHtml '(?is)\bcontact-panel__map\b' 'contact/index.html'
Assert-Matches `
    $contactHtml `
    '(?is)<iframe\b[^>]*src="https://www\.google\.com/maps[^"]*"' `
    'contact/index.html Google Maps embed'

# Issue 9: sticky header polish, raw footer hours, hover parity, uppercase filters, and mode-aware contact accents.
Assert-Matches `
    $homeHeaderSection `
    '(?is)<ul\b[^>]*data-mode-nav="bike"[^>]*>.*?>Merken en verdelers<.*?>Accessoires<.*?>Enkele modellen in de kijker<.*?>Leasing fietsen<.*?>Contact<.*?</ul>' `
    'index.html bike header menu order'
Assert-Matches `
    $homeHeaderSection `
    '(?is)<ul\b[^>]*data-mode-nav="drive"[^>]*>.*?>Merken en verdelers<.*?>Modellen in de kijker<.*?>Winteronderhoud van tuinmachines<.*?>Contact<.*?</ul>' `
    'index.html drive header menu order'
Assert-NotMatches $cssContent '(?is)\.site-header--overlay\s+\.site-brand(?:,|\s*\{).*?opacity\s*:' 'assets/css/style.css overlay logo opacity fade'
Assert-Matches $cssContent '(?is)\.site-header\b[^{}]*\{[^}]*\bposition\s*:\s*sticky\b[^}]*\btop\s*:\s*0' 'assets/css/style.css sticky header hook'
Assert-Matches $modeScriptTemplate 'site-header-scrolled' 'layouts/partials/mode-script.html scrolled header hook'
Assert-NotMatches $cssContent '(?is)\.overview-card\b[^{}]*\{[^}]*\bborder\s*:' 'assets/css/style.css home card border removal'
Assert-NotMatches $cssContent '(?is)\.media-collection__filter\b[^{}]*\{[^}]*font-variant\s*:\s*small-caps' 'assets/css/style.css media collection filter small-caps'
Assert-Matches $cssContent '(?is)\.media-collection__filter\b[^{}]*\{[^}]*text-transform\s*:\s*uppercase' 'assets/css/style.css media collection filter uppercase'
Assert-Matches $cssContent '(?is)\.media-collection__card:hover[^{}]*\{[^}]*transform\s*:\s*translateY' 'assets/css/style.css media collection hover lift'
Assert-Matches $cssContent '(?is)\.media-collection__card:hover\s+\.media-collection__image[^{}]*\{[^}]*transform\s*:\s*scale' 'assets/css/style.css media collection hover zoom'
Assert-Matches $cssContent '(?is)body\[data-site-mode="bike"\][^{]*\{[^}]*--accent\s*:\s*#ffc100' 'assets/css/style.css bike accent variable'
Assert-Matches $cssContent '(?is)body\[data-site-mode="drive"\][^{]*\{[^}]*--accent\s*:\s*#b93f33' 'assets/css/style.css drive accent variable'
Assert-Matches $cssContent '(?is)\.contact-form input\b[^{}]*\{[^}]*border\s*:\s*1px solid (?!var\()' 'assets/css/style.css contact form input border contrast'
Assert-Matches $cssContent '(?is)\.contact-form textarea\b[^{}]*\{[^}]*border\s*:\s*1px solid (?!var\()' 'assets/css/style.css contact form textarea border contrast'
if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'

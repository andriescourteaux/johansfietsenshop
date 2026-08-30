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

    return [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
}

function Read-RepoText {
    param([string]$RelativePath)

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        Add-Problem ('Missing repository file: ' + $RelativePath)
        return $null
    }

    return [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
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


function Get-TomlStringValue {
    param(
        [string]$Content,
        [string]$Key,
        [string]$Context
    )

    if ($null -eq $Content) {
        return $null
    }

    $pattern = '(?m)^\s*' + [regex]::Escape($Key) + '\s*=\s*["''](?<value>[^"'']+)["'']'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        Add-Problem ('Missing TOML string key "' + $Key + '" in ' + $Context)
        return $null
    }

    return $match.Groups['value'].Value.Trim()
}

function Get-TomlBooleanValue {
    param(
        [string]$Content,
        [string]$Key,
        [string]$Context
    )

    if ($null -eq $Content) {
        return $null
    }

    $pattern = '(?m)^\s*' + [regex]::Escape($Key) + '\s*=\s*(?<value>true|false)\b'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        Add-Problem ('Missing TOML boolean key "' + $Key + '" in ' + $Context)
        return $null
    }

    return $match.Groups['value'].Value -eq 'true'
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
$bikeModelsHtml = Read-GeneratedText 'bikeshop/modellen-in-de-kijker/index.html'
$driveModelsHtml = Read-GeneratedText 'driveshop/modellen-in-de-kijker/index.html'
$bikeLeasingHtml = Read-GeneratedText 'bikeshop/leasing-fietsen/index.html'
$bikeAccessoriesHtml = Read-GeneratedText 'bikeshop/accessoires/index.html'
$winterHtml = Read-GeneratedText 'driveshop/winteronderhoud-van-tuinmachines/index.html'
$aboutHtml = Read-GeneratedText 'over-ons/index.html'

$modeScriptTemplate = Read-RepoText 'layouts/partials/mode-script.html'
$sharedHeroTemplate = Read-RepoText 'layouts/partials/shared-hero.html'
$singleTemplate = Read-RepoText 'layouts/_default/single.html'

$baseTemplate = Read-RepoText 'layouts/_default/baseof.html'
$promoPopupTemplate = Read-RepoText 'layouts/partials/promo-popup.html'
$promoPopupScriptTemplate = Read-RepoText 'layouts/partials/promo-popup-script.html'
$promoPopupData = Read-RepoText 'data/promo-popup.toml'
$bikeBrandsData = Read-RepoText 'data/collecties/bikeshop/merken-en-verdelers.toml'
$driveBrandsData = Read-RepoText 'data/collecties/driveshop/merken-en-verdelers.toml'
$bikeBrandsContent = Read-RepoText 'content/merken-en-verdelers-bikeshop.md'
$driveBrandsContent = Read-RepoText 'content/merken-en-verdelers-driveshop.md'
$homeContent = Read-RepoText 'content/_index.md'
$cssContent = if ([string]::IsNullOrWhiteSpace($CssPath)) { $null } else { Read-RepoText $CssPath }


$promoPopupEnabled = Get-TomlBooleanValue $promoPopupData 'enabled' 'data/promo-popup.toml'
$promoPopupImage = Get-TomlStringValue $promoPopupData 'image' 'data/promo-popup.toml'
$promoPopupAlt = Get-TomlStringValue $promoPopupData 'alt' 'data/promo-popup.toml'
$promoPopupTitle = Get-TomlStringValue $promoPopupData 'title' 'data/promo-popup.toml'
$promoPopupBody = Get-TomlStringArray $promoPopupData 'body' 'data/promo-popup.toml'
$promoPopupBullets = Get-TomlStringArray $promoPopupData 'bullets' 'data/promo-popup.toml'
$promoPopupCtaLabel = Get-TomlStringValue $promoPopupData 'cta_label' 'data/promo-popup.toml'
$promoPopupCtaUrl = Get-TomlStringValue $promoPopupData 'cta_url' 'data/promo-popup.toml'
$promoPopupSourceImageExists = $false
if (-not [string]::IsNullOrWhiteSpace($promoPopupImage)) {
    $promoPopupSourcePath = Join-Path $RepoRoot ('static' + $promoPopupImage.Replace('/', [string][System.IO.Path]::DirectorySeparatorChar))
    $promoPopupSourceImageExists = Test-Path -LiteralPath $promoPopupSourcePath
}
$sharedContactData = Read-RepoText 'data/contact.toml'
$sharedContactName = Get-TomlStringValue $sharedContactData 'name' 'data/contact.toml'
$sharedContactAddress = Get-TomlStringValue $sharedContactData 'address' 'data/contact.toml'
$sharedContactEmail = Get-TomlStringValue $sharedContactData 'email' 'data/contact.toml'
$sharedContactPhone = Get-TomlStringValue $sharedContactData 'phone' 'data/contact.toml'
$openingHours = Get-TomlStringArray $sharedContactData 'opening_hours' 'data/contact.toml'
$bikeLandingBody = Get-MarkdownBody 'content/bikeshop.md'
$driveLandingBody = Get-MarkdownBody 'content/driveshop.md'
$eAcute = [string][char]0x00E9
$eDiaeresis = [string][char]0x00EB

$homeHeaderSection = Get-SectionFragment $homeHtml '<header\b[^>]*class="[^"]*\bsite-header\b[^"]*"[^>]*>.*?</header>' 'index.html header'
$homeHeroSection = Get-SectionFragment $homeHtml '<section\b[^>]*class="[^"]*\bshared-hero\b[^"]*"[^>]*>.*?</section>' 'index.html'
$aboutHeroSection = Get-SectionFragment $aboutHtml '<section\b[^>]*class="[^"]*\bshared-hero\b[^"]*"[^>]*>.*?</section>' 'over-ons/index.html'
$homeFooterSection = Get-SectionFragment $homeHtml '<footer\b[^>]*class="[^"]*\bsite-footer\b[^"]*"[^>]*>.*?</footer>' 'index.html footer'
$contactMainSection = Get-SectionFragment $contactHtml '<main\b[^>]*>.*?</main>' 'contact/index.html main'
$bikeNavSection = Get-SectionFragment $homeHeaderSection '<ul\b[^>]*data-mode-nav="bike"[^>]*>.*?</ul>' 'index.html bike header menu'
$driveNavSection = Get-SectionFragment $homeHeaderSection '<ul\b[^>]*data-mode-nav="drive"[^>]*>.*?</ul>' 'index.html drive header menu'

# Feedback redesign target behavior.
Assert-Matches $driveBrandsHtml '(?is)<body\b[^>]*data-site-mode="drive"' 'driveshop/merken-en-verdelers drive mode'
Assert-Matches $driveModelsHtml '(?is)<body\b[^>]*data-site-mode="drive"' 'driveshop/modellen-in-de-kijker drive mode'
Assert-Contains $aboutHtml 'Over ons' 'about page title'
Assert-NotContains $homeContent 'opening_hours' 'content/_index.md opening hours moved'
Assert-NotContains $homeHtml 'opening-hours-section' 'index.html opening hours moved'
Assert-NotContains $contactHtml 'contact-form' 'contact form removed'
Assert-NotMatches $contactHtml '(?is)<form\b' 'contact form removed'
Assert-NotContains $contactHtml 'Vragen, een nieuwe fiets kopen of onderhoud nodig?' 'contact intro removed'
Assert-NotMatches $contactMainSection '(?is)<h1>\s*Contact\s*</h1>' 'contact page title removed'
Assert-Matches $homeHeroSection '(?is)<h1\b(?=[^>]*\bdata-bike-title="Start een nieuw avontuur")(?=[^>]*\bdata-drive-title="Geniet van een perfect verzorgde tuin\.")[^>]*>' 'index.html shared hero h1 title switching'
Assert-Contains $bikeBrandsHtml 'Onze merken' 'bike brands title'
Assert-NotContains $bikeBrandsHtml 'data-media-filter=' 'bike brands filters disabled'
Assert-Contains $homeHtml 'split-block' 'index.html split blocks'
Assert-Contains $homeHtml 'De aankoop van een fiets is het begin van een nieuw avontuur.' 'index.html bike quote'
Assert-NotContains $homeHtml 'overview-card__summary' 'index.html overview card subtitles removed'
Assert-NotContains $homeHtml '<h2>Highlights</h2>' 'index.html highlights heading removed'
Assert-NotContains $aboutHtml '<h2>Highlights</h2>' 'over-ons/index.html highlights heading removed'
Assert-NotContains $homeHtml 'home-highlight__intro' 'index.html highlight descriptions removed'
Assert-NotContains $aboutHtml 'home-highlight__intro' 'over-ons/index.html highlight descriptions removed'
foreach ($highlightName in @(
    'Flanders Navigator',
    'Gazelle Eclipse Speed',
    'HPlus POWERDRIVE Pinion Sport'
)) {
    $highlightTitle = '<span class="home-highlight__title">' + $highlightName + '</span>'
    Assert-Contains $homeHtml $highlightTitle 'index.html complete highlight names'
    Assert-Contains $aboutHtml $highlightTitle 'over-ons/index.html complete highlight names'
}
foreach ($highlightLink in @(
    'https://www.gazellebikes.com/nl-be',
    'https://flandersfietsen.be/wp/',
    'https://www.hplus-mobility.com/en_GB'
)) {
    Assert-Contains $homeHtml $highlightLink 'index.html manufacturer highlight links'
    Assert-Contains $aboutHtml $highlightLink 'over-ons/index.html manufacturer highlight links'
}
$drivePanelStart = $homeHtml.IndexOf('home-overview__panel--drive')
if ($drivePanelStart -lt 0) {
    Add-Problem 'Missing drive homepage panel in index.html'
}
else {
    Assert-NotContains $homeHtml.Substring($drivePanelStart) 'De aankoop van een fiets is het begin van een nieuw avontuur.' 'index.html drive panel bike quote'
    foreach ($driveHighlightName in @(
        'Compacttractor',
        'Tuinmachine',
        'Zitmaaier'
    )) {
        Assert-Contains $homeHtml.Substring($drivePanelStart) ('<span class="home-highlight__title">' + $driveHighlightName + '</span>') 'index.html drive model highlights'
    }
    Assert-NotContains $homeHtml.Substring($drivePanelStart) '<span class="home-highlight__title">Gazelle Eclipse Speed</span>' 'index.html drive panel bike highlight removed'
}
Assert-Contains $bikeBrandsHtml 'media-collection--split-blocks' 'bike brands split blocks'
Assert-Contains $driveBrandsHtml 'media-collection--split-blocks' 'drive brands split blocks'
Assert-Contains $bikeLeasingHtml 'media-collection--split-blocks' 'bike leasing split blocks'
Assert-Contains $bikeLeasingHtml 'data-collection-key="leasing-fietsen"' 'bike leasing collection key hook'
Assert-Contains $bikeLeasingHtml 'data-collection-item="welease.svg"' 'bike leasing Welease item hook'
Assert-Contains $bikeAccessoriesHtml 'media-collection--split-blocks' 'bike accessories split blocks'
Assert-Contains $bikeBrandsHtml ('effici' + $eDiaeresis + 'nt en betrouwbaar vervoermiddel') 'bike brands accented copy'
Assert-Contains $bikeLeasingHtml ('We cre' + $eDiaeresis + 'ren samen enthousiasme') 'bike leasing accented copy'
Assert-Contains $bikeAccessoriesHtml ('essenti' + $eDiaeresis + 'le fietsonderdelen') 'bike accessories accented copy'
Assert-Contains $driveBrandsHtml ('Betrouwbare en effici' + $eDiaeresis + 'nte grasmachines') 'drive brands accented copy'
Assert-Contains $aboutHtml ($eAcute + $eAcute + 'n ding') 'about accented copy'
Assert-Contains $aboutHtml ($eAcute + 'cht nodig heeft') 'about accented copy'
Assert-NotContains $aboutHeroSection '/images/about/headshot.webp' 'over-ons/index.html headshot hero override removed'
Assert-Contains $aboutHeroSection '/images/header_bike_2.webp' 'over-ons/index.html default bike hero'
Assert-Contains $aboutHtml 'page-value' 'over-ons/index.html page values'
Assert-Contains $contactHtml 'page-value' 'contact/index.html page values'
Assert-Contains $aboutHtml '&#128295;' 'over-ons/index.html about emoji'
Assert-Contains $aboutHtml '&#9989;' 'over-ons/index.html about emoji'
Assert-Contains $aboutHtml '&#128690;' 'over-ons/index.html about emoji'
Assert-NotMatches $homeHtml '(?is)<a\b[^>]*href="[^"]*/bikeshop/modellen-in-de-kijker/' 'index.html old bike models link'
Assert-NotMatches $homeHtml '(?is)<a\b[^>]*href="[^"]*/driveshop/modellen-in-de-kijker/' 'index.html old drive models link'
Assert-NotContains $homeHtml 'Enkele modellen in de kijker' 'index.html old bike models label'
Assert-NotContains $homeHtml 'Modellen in de kijker' 'index.html old drive models label'
Assert-Contains $bikeAccessoriesHtml 'https://www.basil.com/nl/' 'bike accessories Basil link'
Assert-Contains $bikeAccessoriesHtml 'https://shop.vdbparts.be/' 'bike accessories VDB Parts link'
Assert-Contains $bikeAccessoriesHtml 'https://axabikesecurity.com/nl/' 'bike accessories Axa link'
Assert-Contains $bikeAccessoriesHtml 'https://www.verwimp.nl/nl' 'bike accessories Louis Verwimp link'
Assert-Contains $bikeAccessoriesHtml 'https://www.thule.com/nl-be/' 'bike accessories Thule link'
Assert-Contains $bikeAccessoriesHtml 'Bekijk assortiment' 'bike accessories buttons'
Assert-Contains $bikeBrandsHtml 'Meer info' 'bike brands buttons'
Assert-Contains $driveBrandsHtml 'Meer info' 'drive brands buttons'
Assert-NotContains $bikeBrandsHtml 'split-block__media-link' 'bike brands image links removed'
Assert-NotContains $driveBrandsHtml 'split-block__media-link' 'drive brands image links removed'
Assert-Contains $contactHtml 'Betaal mogelijkheden' 'contact payment methods'
Assert-Contains $contactHtml '/images/payment/cash.png' 'contact cash payment icon'
Assert-Contains $contactHtml '/images/payment/bancontact.svg' 'contact bancontact payment icon'
Assert-Contains $contactHtml '/images/payment/payconiq.png' 'contact payconiq payment icon'
Assert-Contains $contactHtml 'Vervangfiets' 'contact replacement bike block'
Assert-Contains $contactHtml 'Ophaaldienst' 'contact pickup block'
Assert-Matches $contactMainSection '(?is)Herstellingen &amp; Onderhoud.*?Fiets kopen\?.*?Vervangfiets.*?Ophaaldienst.*?contact-page__actions' 'contact/index.html page values grouped before actions'
Assert-Contains $contactHtml 'contact-page__button-icon' 'contact icon buttons'
Assert-Contains $winterHtml 'Maak je tuinmachines winterklaar' 'winter maintenance title'
Assert-Contains $winterHtml 'Unieke service: Wij halen en brengen je machine' 'winter maintenance pickup section'
Assert-Contains $winterHtml 'Interesse of direct inplannen?' 'winter maintenance planning section'
Assert-Contains $winterHtml 'Neem contact op' 'winter contact CTA'
$winterValueCards = @([regex]::Matches($winterHtml, 'class="winter-value page-value"'))
Assert-True ($winterValueCards.Count -eq 8) 'winter maintenance value cards'
foreach ($winterValue in @(
    @{ Title = 'Betrouwbaarheid'; Text = 'Geen startproblemen in het voorjaar.' },
    @{ Title = 'Gezondheid'; Text = 'Langere levensduur van je motor, accu en bewegende delen.' },
    @{ Title = 'Scherp en veilig'; Text = 'Messen worden geslepen en gebalanceerd voor een perfect maairesultaat.' },
    @{ Title = 'Optimaal gemak'; Text = 'Wij doen het zware werk.' },
    @{ Title = 'Aanmelden'; Text = 'Geef je machine op voor onderhoud.' },
    @{ Title = 'Ophalen'; Text = 'Wij halen de machine bij je thuis op wanneer het uitkomt.' },
    @{ Title = 'Onderhoud'; Text = 'We voeren een complete inspectie en onderhoudsbeurt uit.' },
    @{ Title = 'Terugbrengen'; Text = 'Je krijgt je machine netjes onderhouden en startklaar weer thuisbezorgd.' }
)) {
    Assert-Matches $winterHtml ('(?is)<article class="winter-value page-value">\s*<h2>' + [regex]::Escape($winterValue.Title) + '</h2>\s*<p>' + [regex]::Escape($winterValue.Text) + '</p>\s*</article>') 'winter maintenance split bullet cards'
}
Assert-NotMatches $winterHtml '(?is)<li>\s*(?:Betrouwbaarheid|Gezondheid|Scherp en veilig|Optimaal gemak|Aanmelden|Ophalen|Onderhoud|Terugbrengen)\s*:' 'winter maintenance bullets converted to page values'

# Issue 1: shared-page footer links must be drive-mode aware in the mode script.
Assert-Contains $homeHtml 'site-footer__link--contact' 'index.html'
Assert-Contains $homeHtml 'site-footer__link--merken' 'index.html'
Assert-Contains $contactHtml 'site-footer__link--contact' 'contact/index.html'
Assert-Contains $contactHtml 'site-footer__link--merken' 'contact/index.html'
Assert-Matches $homeHtml '(?is)<link\b[^>]*rel="?stylesheet"?[^>]*href="\./css/' 'index.html GitHub Pages stylesheet path'
Assert-NotMatches $homeHtml '(?is)<link\b[^>]*rel="?stylesheet"?[^>]*href="\./johansfietsenshop/css/' 'index.html duplicated GitHub Pages stylesheet path'
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
Assert-NotContains $bikeBrandsHtml "L'Avenir" 'bikeshop/merken-en-verdelers/index.html removed LAvenir'
Assert-NotContains $bikeBrandsHtml 'lavenir.svg' 'bikeshop/merken-en-verdelers/index.html removed LAvenir'
Assert-Contains $bikeBrandsHtml 'class="split-block__logo"' 'bikeshop/merken-en-verdelers/index.html logo titles'
Assert-Contains $bikeBrandsHtml 'data-collection-item="tb_bfk.jpg"' 'bikeshop/merken-en-verdelers/index.html'
Assert-Matches $bikeBrandsHtml '(?is)<img class="split-block__logo" src="[^"]*/images/collecties/bikeshop/merken-en-verdelers/bfk\.webp" alt="BFK logo"' 'bikeshop/merken-en-verdelers/index.html'
Assert-NotContains $bikeBrandsHtml '<h2 class="split-block__title">BFK</h2>' 'bikeshop/merken-en-verdelers/index.html BFK text title replaced'
Assert-Contains $bikeBrandsHtml 'https://shop.vdbparts.be/collections/bike-fun-kids' 'bikeshop/merken-en-verdelers/index.html BFK link'
Assert-NotMatches $bikeBrandsHtml '(?is)<article\b[^>]*data-collection-item="tb_bfk\.jpg"[^>]*>.*?href="https://flandersfietsen\.be/wp/"' 'bikeshop/merken-en-verdelers/index.html'
foreach ($bikeTbImage in @(
    'tb_swyff.jpg',
    'tb_oxford.jpg',
    'tb_thompson.jpg',
    'tb_zannata.jpg',
    'tb_gazelle.webp',
    'tb_descheemaeker.jpg',
    'tb_flanders.jpg',
    'tb_bfk.jpg',
    'tb_ravr.jpg'
)) {
    Assert-Matches $bikeBrandsHtml ('(?is)<img class="split-block__image" src="[^"]*/images/collecties/bikeshop/merken-en-verdelers/' + [regex]::Escape($bikeTbImage) + '"') 'bikeshop/merken-en-verdelers/index.html tb block images'
}
foreach ($driveLogo in @(
    'vegemac.webp',
    'iseki.webp',
    'castelgarden.webp',
    'stiga.webp',
    'makita.png'
)) {
    Assert-Matches $driveBrandsHtml ('(?is)<img class="split-block__logo" src="[^"]*/images/collecties/driveshop/merken-en-verdelers/' + [regex]::Escape($driveLogo) + '"') 'driveshop/merken-en-verdelers/index.html logo titles'
}
Assert-NotMatches $driveBrandsHtml '(?is)<img\b[^>]*class="split-block__logo"[^>]*src="[^"]*_tb\.' 'driveshop/merken-en-verdelers/index.html title logos use non-tb files'
foreach ($driveTbImage in @(
    'vegemac_tb.webp',
    'iseki_tb.jpg',
    'castelgarden_tb.webp',
    'stiga_tb.png',
    'makita_tb.jpg'
)) {
    Assert-Matches $driveBrandsHtml ('(?is)<img class="split-block__image" src="[^"]*/images/collecties/driveshop/merken-en-verdelers/' + [regex]::Escape($driveTbImage) + '"') 'driveshop/merken-en-verdelers/index.html tb block images'
}

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

# Issue 6: opening hours move to contact/footer, cards use webp, and header toggle typography is centralized.
Assert-NotMatches $homeHeroSection '(?is)<(?:div|section)[^>]*class="[^"]*\bopening-hours\b[^"]*"' 'index.html shared hero'

foreach ($hoursLine in $openingHours) {
    $serialized = [regex]::Replace($hoursLine, '^([^:]+):\s*(.*)$', '$1||$2')
    $parts = $serialized -split '\|\|', 2
    $day = $parts[0]
    $slots = @()
    if ($parts.Count -gt 1) {
        $slots = @($parts[1] -split '\s*\|\s*' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    $hoursPattern = '(?is)' + [regex]::Escape($day)
    if ($slots.Count -gt 0) {
        $hoursPattern += '.*?' + (($slots | ForEach-Object { [regex]::Escape($_) }) -join '.*?')
    }

    Assert-Matches $contactMainSection $hoursPattern 'contact/index.html opening hours'
    Assert-Matches $homeFooterSection $hoursPattern 'index.html footer opening hours'
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

# Issue 8: hero eyebrow removed, contact stays inside the dropdown, and the contact page exposes the expected hooks.
Assert-NotContains $sharedHeroTemplate 'Site2' 'layouts/partials/shared-hero.html'
Assert-NotContains $homeHeroSection 'Site2' 'index.html shared hero'
Assert-NotContains $homeHeaderSection 'site-nav__contact' 'index.html header'
Assert-NotContains $modeScriptTemplate "applyHref('.site-nav__contact');" 'layouts/partials/mode-script.html'
Assert-Matches `
    $modeScriptTemplate `
    "(?s)const openMenu = \(\) => \{.*?menu\.hidden = false;.*?applyMenuState\('closed'\);.*?requestAnimationFrame\(\(\) => \{.*?applyMenuState\('opening'\);" `
    'layouts/partials/mode-script.html menu opening animation hook'

Assert-Matches $contactHtml '(?is)\bcontact-page__block\b' 'contact/index.html'
Assert-Matches $contactHtml '(?is)\bcontact-page__button\b' 'contact/index.html'
Assert-Matches $contactHtml '(?is)\bcontact-panel__map\b' 'contact/index.html'
Assert-Matches `
    $contactHtml `
    '(?is)<iframe\b[^>]*src="https://www\.google\.com/maps[^"]*"' `
    'contact/index.html Google Maps embed'

# Issue 9: sticky header polish, raw footer hours, hover parity, uppercase filters, and mode-aware accents.
foreach ($navLabel in @('Onze merken', 'Accessoires', 'Leasing fietsen', 'Over ons', 'Contact')) {
    Assert-Contains $bikeNavSection $navLabel 'index.html bike header menu'
}

foreach ($navLabel in @('Onze merken', 'Winteronderhoud', 'Over ons', 'Contact')) {
    Assert-Contains $driveNavSection $navLabel 'index.html drive header menu'
}

Assert-NotContains $homeHeaderSection 'Enkele modellen in de kijker' 'index.html header menu old bike models label'
Assert-NotContains $homeHeaderSection 'Modellen in de kijker' 'index.html header menu old drive models label'
Assert-NotContains $homeHeaderSection 'Winteronderhoud van tuinmachines' 'index.html header menu old winter label'
Assert-NotContains $homeHeaderSection 'Merken en verdelers' 'index.html header menu old brands label'
Assert-NotMatches $cssContent '(?is)\\.site-header--overlay\\s+\\.site-brand\\s*,\\s*\\.site-header--overlay\\s+\\.site-brand:hover\\s*,\\s*\\.site-header--overlay\\s+\\.site-brand:focus-visible\\s*\\{[^}]*opacity\\s*:' 'assets/css/style.css overlay logo opacity fade'
Assert-Matches $cssContent '(?is)\.site-header\b[^{}]*\{[^}]*\bposition\s*:\s*sticky\b[^}]*\btop\s*:\s*0' 'assets/css/style.css sticky header hook'
Assert-Matches $cssContent '(?is)\.site-header--overlay\b[^{}]*\{[^}]*\bposition\s*:\s*fixed\b[^}]*\btop\s*:\s*0\b[^}]*\bleft\s*:\s*0\b[^}]*\bright\s*:\s*0' 'assets/css/style.css overlay hero header positioning'
Assert-Matches $cssContent '(?is)\.site-header--overlay\b[^{}]*\{[^}]*\bposition\s*:\s*fixed\b[^}]*\btop\s*:\s*0\b[^}]*\bleft\s*:\s*0\b[^}]*\bright\s*:\s*0' 'assets/css/style.css overlay hero header positioning'
Assert-Matches $modeScriptTemplate 'site-header-scrolled' 'layouts/partials/mode-script.html scrolled header hook'
Assert-NotMatches $cssContent '(?is)\.overview-card\b[^{}]*\{[^}]*\bborder\s*:' 'assets/css/style.css home card border removal'
Assert-NotMatches $cssContent '(?is)\.media-collection__filter\b[^{}]*\{[^}]*font-variant\s*:\s*small-caps' 'assets/css/style.css media collection filter small-caps'
Assert-Matches $cssContent '(?is)\.media-collection__filter\b[^{}]*\{[^}]*text-transform\s*:\s*uppercase' 'assets/css/style.css media collection filter uppercase'
Assert-Matches $cssContent '(?is)\.media-collection__card:hover[^{}]*\{[^}]*transform\s*:\s*translateY' 'assets/css/style.css media collection hover lift'
Assert-Matches $cssContent '(?is)\.media-collection__card:hover\s+\.media-collection__image[^{}]*\{[^}]*transform\s*:\s*scale' 'assets/css/style.css media collection hover zoom'
Assert-Matches $cssContent '(?is):root\s*\{[^}]*--container\s*:\s*124rem' 'assets/css/style.css wider page canvas'
Assert-Matches $cssContent '(?is)\.split-block__media\b[^{}]*\{[^}]*aspect-ratio\s*:\s*1\s*/\s*1' 'assets/css/style.css square split block images'
Assert-Matches $cssContent '(?is)\.page-intro\s+\.container\b[^{}]*\{[^}]*box-shadow\s*:\s*none' 'assets/css/style.css page canvas shadow removed'
Assert-Matches $cssContent '(?is)\.page--home\s+\.home-hero\b[^{}]*\{[^}]*align-items\s*:\s*center' 'assets/css/style.css centered home hero titles'
Assert-Matches $cssContent '(?is)\.page--home\s+\.home-hero__content\b[^{}]*\{[^}]*text-align\s*:\s*center' 'assets/css/style.css centered home hero titles'
Assert-Matches $cssContent '(?is)\.page--home\s+\.home-hero__content\b[^{}]*\{[^}]*transform\s*:\s*translateY\(-4vh\)' 'assets/css/style.css lifted home hero titles'
Assert-Matches $cssContent '(?is)\.home-overview__panel--bike\s+\.home-overview__grid\b[^{}]*\{[^}]*repeat\(3,\s*minmax\(0,\s*27rem\)\)' 'assets/css/style.css larger bike overview cards'
Assert-Matches $cssContent '(?is)\.home-overview__panel--drive\s+\.home-overview__grid\b[^{}]*\{[^}]*repeat\(2,\s*minmax\(0,\s*27rem\)\)' 'assets/css/style.css larger drive overview cards'
Assert-Matches $cssContent '(?is)\.overview-card\b[^{}]*\{[^}]*min-height\s*:\s*18rem' 'assets/css/style.css taller overview cards'
Assert-Matches $cssContent '(?is)\.overview-card__body\b[^{}]*\{[^}]*min-height\s*:\s*18rem' 'assets/css/style.css taller overview card body'
Assert-Matches $cssContent '(?is)\.home-overview__grid\s*\+\s*\.home-mode-sections\b(?=[^{}]*\{[^}]*position\s*:\s*relative)(?=[^{}]*\{[^}]*margin-top\s*:\s*clamp\(9rem,\s*17vw,\s*14rem\))' 'assets/css/style.css more space below overview cards'
Assert-Matches $cssContent '(?is)\.home-overview__grid\s*\+\s*\.home-mode-sections::before\b(?=[^{}]*\{[^}]*display\s*:\s*block)(?=[^{}]*\{[^}]*height\s*:\s*clamp\(7\.5rem,\s*15vw,\s*12rem\))(?=[^{}]*\{[^}]*margin-bottom\s*:\s*clamp\(2rem,\s*5vw,\s*4rem\))(?=[^{}]*\{[^}]*background\s*:\s*#f4f4f4)(?=[^{}]*\{[^}]*box-shadow\s*:\s*0\s+0\s+0\s+100vmax\s+#f4f4f4)' 'assets/css/style.css homepage separator plane'
Assert-NotMatches $cssContent '(?is)\.home-overview__grid\s*\+\s*\.home-mode-sections::before\b[^{}]*\{[^}]*position\s*:\s*absolute' 'assets/css/style.css homepage separator does not overlap split blocks'
Assert-NotMatches $cssContent '(?is)\.home-overview__grid\s*\+\s*\.home-mode-sections::before\b[^{}]*\{[^}]*top\s*:' 'assets/css/style.css homepage separator does not overlap split blocks'
Assert-Matches $cssContent '(?is)\.home-quote\b[^{}]*\{[^}]*margin-top\s*:\s*clamp\(9rem,\s*18vw,\s*15rem\)[^}]*margin-bottom\s*:\s*clamp\(9rem,\s*18vw,\s*15rem\)' 'assets/css/style.css homepage quote vertical spacing'
Assert-Matches $cssContent '(?is)\.home-highlight\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css borderless highlights'
Assert-Matches $cssContent '(?is)\.home-highlight\b[^{}]*\{[^}]*background\s*:\s*#fff' 'assets/css/style.css white highlight cards'
Assert-Matches $cssContent '(?is)\.home-highlight__body\b[^{}]*\{[^}]*text-align\s*:\s*left' 'assets/css/style.css left aligned highlight names'
Assert-Matches $cssContent '(?is)\.home-highlights\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css borderless highlight support plane'
Assert-Matches $cssContent '(?is)\.home-highlights\b[^{}]*\{[^}]*background\s*:\s*#f4f4f4' 'assets/css/style.css highlight support plane'
Assert-Matches $cssContent '(?is)\.home-highlights\b[^{}]*\{[^}]*box-shadow\s*:\s*0\s+0\s+0\s+100vmax\s+#f4f4f4' 'assets/css/style.css full bleed highlight support plane'
Assert-Matches $cssContent '(?is)\.media-collection--split-blocks\[data-collection-key="leasing-fietsen"\]\s+\.split-block__media\b[^{}]*\{[^}]*padding\s*:' 'assets/css/style.css leasing logo padding'
Assert-Matches $cssContent '(?is)\.media-collection--split-blocks\[data-collection-key="leasing-fietsen"\]\s+\.split-block__image\b[^{}]*\{[^}]*object-fit\s*:\s*contain' 'assets/css/style.css contained leasing logos'
Assert-Matches $cssContent '(?is)\.media-collection--split-blocks\[data-collection-key="leasing-fietsen"\]\s+\.split-block\[data-collection-item="welease\.svg"\]\s+\.split-block__media\b[^{}]*\{[^}]*border\s*:\s*0[^}]*background\s*:\s*#17122f' 'assets/css/style.css Welease picture background'
Assert-Matches $cssContent '(?is)\.split-block__logo\b[^{}]*\{[^}]*height\s*:\s*5rem[^}]*object-fit\s*:\s*contain' 'assets/css/style.css normalized split block logo titles'
Assert-Matches $cssContent '(?is)\.page-value\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css borderless page values'
Assert-Matches $cssContent '(?is)\.page-value\b[^{}]*\{[^}]*background\s*:\s*transparent' 'assets/css/style.css page value gradients removed'
Assert-NotMatches $cssContent '(?is)\.page-value\b[^{}]*\{[^}]*linear-gradient' 'assets/css/style.css page value gradients removed'
Assert-Matches $cssContent '(?is)\.page-value\s+h2\b[^{}]*\{[^}]*text-transform\s*:\s*uppercase' 'assets/css/style.css uppercase page value titles'
Assert-Matches $cssContent '(?is)\.contact-page__hours\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css contact hours border removed'
Assert-Matches $cssContent '(?is)\.contact-page__payments\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css payment border removed'
Assert-Matches $cssContent '(?is)\.contact-page__payments\b[^{}]*\{[^}]*background\s*:\s*transparent' 'assets/css/style.css payment background removed'
Assert-Matches $cssContent '(?is)\.contact-page__hours\s+h2\s*,\s*\.contact-page__payments\s+h2\b[^{}]*\{[^}]*text-align\s*:\s*center' 'assets/css/style.css centered contact section titles'
Assert-Matches $cssContent '(?is)\.contact-page__grid\b[^{}]*\{[^}]*grid-template-columns\s*:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\)' 'assets/css/style.css contact page values 2x2 grid'
Assert-NotMatches $cssContent '(?is)@media\s*\(max-width:\s*640px\)\s*\{[^@]*\.contact-page__grid[^@]*grid-template-columns\s*:\s*1fr' 'assets/css/style.css contact page values stay 2x2'
Assert-Matches $cssContent '(?is)\.contact-page__payments\s+li\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css payment icon border removed'
Assert-Matches $cssContent '(?is)\.contact-page__payments\s+li\b[^{}]*\{[^}]*background\s*:\s*transparent' 'assets/css/style.css payment icon background removed'
Assert-Matches $cssContent '(?is)\.contact-page__actions\b[^{}]*\{[^}]*justify-content\s*:\s*center' 'assets/css/style.css centered contact buttons'
Assert-Matches $cssContent '(?is)\.contact-page__actions\b[^{}]*\{[^}]*gap\s*:\s*clamp\(3rem,\s*8vw,\s*6rem\)' 'assets/css/style.css wider contact icon gap'
Assert-Matches $cssContent '(?is)\.contact-page__button\b[^{}]*\{[^}]*width\s*:\s*clamp\(6\.5rem,\s*12vw,\s*8rem\)[^}]*height\s*:\s*clamp\(6\.5rem,\s*12vw,\s*8rem\)' 'assets/css/style.css larger contact buttons'
Assert-Matches $cssContent '(?is)\.contact-page__button-icon\b[^{}]*\{[^}]*width\s*:\s*clamp\(3\.8rem,\s*7vw,\s*4\.75rem\)' 'assets/css/style.css larger contact icons'
Assert-Matches $cssContent '(?is)\.contact-page__payments\s+h2\b[^{}]*\{[^}]*font-size\s*:\s*1\.6rem' 'assets/css/style.css larger payment heading'
Assert-Matches $cssContent '(?is)\.contact-page__payments\s+ul\b[^{}]*\{[^}]*display\s*:\s*flex[^}]*gap\s*:\s*clamp\(0\.25rem,\s*1vw,\s*0\.5rem\)' 'assets/css/style.css tighter payment icon layout'
Assert-Matches $cssContent '(?is)\.contact-page__payments\s+li\b(?=[^{}]*\{[^}]*min-height\s*:\s*8\.5rem)(?=[^{}]*\{[^}]*min-width\s*:\s*8rem)' 'assets/css/style.css larger payment tiles'
Assert-Matches $cssContent '(?is)\.contact-page__payments\s+img\b[^{}]*\{[^}]*max-height\s*:\s*5\.25rem' 'assets/css/style.css larger payment icons'
Assert-Matches $cssContent '(?is)\.contact-page\s+\.opening-hours-table\s+th\s*,\s*\.contact-page\s+\.opening-hours-table\s+td\b[^{}]*\{[^}]*text-align\s*:\s*center' 'assets/css/style.css centered contact timetable'
Assert-Matches $cssContent '(?is)\.page-copy--narrow\b[^{}]*\{[^}]*max-width\s*:\s*40rem' 'assets/css/style.css narrow page copy'
Assert-Matches $cssContent '(?is)\.page-intro--center\s+h1\b[^{}]*\{[^}]*text-align\s*:\s*center' 'assets/css/style.css centered page title'
Assert-Matches $cssContent '(?is)\.page-copy--center\b[^{}]*\{[^}]*text-align\s*:\s*center' 'assets/css/style.css centered page copy'
Assert-Matches $cssContent '(?is)\.winter-values__grid\b[^{}]*\{[^}]*grid-template-columns\s*:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\)' 'assets/css/style.css winter value grid'
Assert-NotMatches $cssContent '(?is)\.winter-values__grid\b[^{}]*\{[^}]*grid-template-columns\s*:\s*repeat\(4,\s*minmax\(0,\s*1fr\)\)' 'assets/css/style.css winter value grid not four columns'
Assert-NotMatches $cssContent '(?is)@media\s*\(max-width:\s*720px\)\s*\{[^@]*\.winter-values__grid[^@]*grid-template-columns\s*:\s*1fr' 'assets/css/style.css winter value grid stays 2x2'
Assert-Matches $cssContent '(?is)\.winter-values\b[^{}]*\{[^}]*margin\s*:\s*clamp\(1\.5rem,\s*5vw,\s*3\.5rem\)\s+0' 'assets/css/style.css winter values separated from copy'
Assert-Matches $cssContent '(?is)\.winter-value\.page-value\b[^{}]*\{(?=[^}]*padding\s*:\s*clamp\(1\.75rem,\s*4vw,\s*2\.75rem\))(?=[^}]*min-height\s*:\s*clamp\(12rem,\s*18vw,\s*15rem\))' 'assets/css/style.css larger winter value cards'
Assert-Matches $cssContent '(?is)\.page-copy\b[^{}]*\{[^}]*color\s*:\s*var\(--text\)' 'assets/css/style.css black page copy'
Assert-Matches $cssContent '(?is)\.contact-page__block\s+p\b[^{}]*\{[^}]*color\s*:\s*var\(--text\)' 'assets/css/style.css black contact page text'
Assert-Matches $cssContent '(?is)\.about-page__vision\s+p\s*,\s*\.about-page__value\s+p\b[^{}]*\{[^}]*color\s*:\s*var\(--text\)' 'assets/css/style.css black about page text'
Assert-Matches $cssContent '(?is)\.split-block__intro\b[^{}]*\{[^}]*color\s*:\s*var\(--text\)' 'assets/css/style.css black split block text'
Assert-Matches $cssContent '(?is)\.media-showcase__intro\b[^{}]*\{[^}]*color\s*:\s*var\(--text\)' 'assets/css/style.css black showcase page text'
Assert-Matches $cssContent '(?is)\.page-cta\b[^{}]*\{[^}]*border\s*:\s*0' 'assets/css/style.css CTA canvas border removed'
Assert-Matches $cssContent '(?is)\.page-cta\b[^{}]*\{[^}]*background\s*:\s*transparent' 'assets/css/style.css CTA canvas background removed'
Assert-Matches $cssContent '(?is)\.page-cta\b[^{}]*\{[^}]*text-align\s*:\s*center' 'assets/css/style.css centered CTA canvas'
Assert-Matches $cssContent '(?is)body\[data-site-mode="bike"\][^{]*\{[^}]*--accent\s*:\s*#ffc100' 'assets/css/style.css bike accent variable'
Assert-Matches $cssContent '(?is)body\[data-site-mode="bike"\][^{]*\{[^}]*--accent-rgb\s*:\s*255,\s*193,\s*0' 'assets/css/style.css bike accent rgb variable'
Assert-Matches $cssContent '(?is)body\[data-site-mode="drive"\][^{]*\{[^}]*--accent\s*:\s*#b93f33' 'assets/css/style.css drive accent variable'
Assert-Matches $cssContent '(?is)body\[data-site-mode="drive"\][^{]*\{[^}]*--accent-rgb\s*:\s*185,\s*63,\s*51' 'assets/css/style.css drive accent rgb variable'

# Issue 10: session promo popup must be globally wired, data-driven, and honor enabled state.
Assert-Contains $baseTemplate 'partial "promo-popup.html" .' 'layouts/_default/baseof.html'
Assert-Contains $baseTemplate 'partial "promo-popup-script.html" .' 'layouts/_default/baseof.html'
Assert-Contains $promoPopupTemplate 'data-promo-popup="root"' 'layouts/partials/promo-popup.html'
Assert-Contains $promoPopupTemplate 'data-promo-popup="backdrop"' 'layouts/partials/promo-popup.html'
Assert-Contains $promoPopupTemplate 'data-promo-popup="close"' 'layouts/partials/promo-popup.html'
Assert-Contains $promoPopupTemplate 'data-promo-popup-key=' 'layouts/partials/promo-popup.html'
Assert-Contains $promoPopupTemplate 'fileExists' 'layouts/partials/promo-popup.html local image priority'
Assert-Contains $promoPopupTemplate '{{ else }}' 'layouts/partials/promo-popup.html text fallback branch'
Assert-Matches $promoPopupTemplate '(?is)(?:index\s+[^}]+["'']title["'']|\$[a-z0-9_]*title\b|\.title\b)' 'layouts/partials/promo-popup.html title fallback'
Assert-Matches $promoPopupTemplate '(?is)(?:index\s+[^}]+["'']body["'']|\$[a-z0-9_]*body\b|\.body\b)' 'layouts/partials/promo-popup.html body fallback'
Assert-Matches $promoPopupTemplate '(?is)(?:index\s+[^}]+["'']bullets["'']|\$[a-z0-9_]*bullets\b|\.bullets\b)' 'layouts/partials/promo-popup.html bullets fallback'
Assert-Matches $promoPopupTemplate '(?is)(?:index\s+[^}]+["'']cta_label["'']|\$[a-z0-9_]*(?:cta_label|ctaLabel)\b|\.(?:cta_label|ctaLabel)\b)' 'layouts/partials/promo-popup.html CTA label fallback'
Assert-Matches $promoPopupTemplate '(?is)(?:index\s+[^}]+["'']cta_url["'']|\$[a-z0-9_]*(?:cta_url|ctaUrl)\b|\.(?:cta_url|ctaUrl)\b)' 'layouts/partials/promo-popup.html CTA URL fallback'
Assert-Contains $promoPopupScriptTemplate 'root.dataset.promoPopupKey' 'layouts/partials/promo-popup-script.html'
Assert-Contains $promoPopupScriptTemplate 'sessionStorage' 'layouts/partials/promo-popup-script.html'
Assert-Matches $cssContent '(?is)\.promo-popup\[hidden\][^{}]*\{[^}]*display\s*:\s*none' 'assets/css/style.css promo popup hidden display reset'
Assert-Matches $cssContent '(?is)\.promo-popup__dialog[^{}]*\{[^}]*width\s*:\s*min\(\s*52vw\s*,\s*52rem\s*\)' 'assets/css/style.css promo popup larger dialog width'
Assert-Matches $cssContent '(?is)\.promo-popup\[data-state="(?:closed|closing)"\][^{}]*\{[^}]*pointer-events\s*:\s*none' 'assets/css/style.css promo popup closed pointer events'
Assert-NotMatches $cssContent '(?is)\.shared-hero\b[^{}]*\{[^}]*z-index\s*:\s*-' 'assets/css/style.css shared hero negative z-index'
Assert-Matches $cssContent '(?is)\.page-intro--after-hero\s+\.container\b[^{}]*\{[^}]*margin-top\s*:\s*-50vh' 'assets/css/style.css single page intro overlap restore'
Assert-Matches $cssContent '(?is)\.page-intro--after-hero\b[^{}]*\{[^}]*position\s*:\s*relative' 'assets/css/style.css single page intro stacking context'
Assert-Matches $cssContent '(?is)\.page-intro--after-hero\s+\.container\b[^{}]*\{[^}]*z-index\s*:\s*2' 'assets/css/style.css single page intro foreground layer'

if ($promoPopupEnabled -eq $true) {
    Assert-Matches $homeHtml '(?is)<div\b[^>]*data-promo-popup="root"' 'index.html promo popup root'
    Assert-Matches $homeHtml '(?is)<button\b[^>]*data-promo-popup="backdrop"' 'index.html promo popup backdrop'
    Assert-Matches $homeHtml '(?is)<button\b[^>]*data-promo-popup="close"' 'index.html promo popup close'
    Assert-Contains $homeHtml 'promo-popup-script' 'index.html promo popup'

    if (-not [string]::IsNullOrWhiteSpace($promoPopupImage) -and $promoPopupSourceImageExists) {
        Assert-Matches $homeHtml ('(?is)<img\b[^>]*src="[^"]*' + [regex]::Escape($promoPopupImage) + '"') 'index.html promo popup image'
        if (-not [string]::IsNullOrWhiteSpace($promoPopupAlt)) {
            Assert-Matches $homeHtml ('(?is)<img\b[^>]*alt="' + [regex]::Escape($promoPopupAlt) + '"') 'index.html promo popup image alt'
        }
        Assert-NotContains $homeHtml 'promo-popup__content' 'index.html promo popup image priority'
        Assert-NotContains $homeHtml $promoPopupTitle 'index.html promo popup image priority title fallback'
    }
    else {
        Assert-NotMatches $homeHtml ('(?is)<img\b[^>]*src="[^"]*' + [regex]::Escape($promoPopupImage) + '"') 'index.html promo popup missing image fallback'
        Assert-Contains $homeHtml $promoPopupTitle 'index.html promo popup fallback title'
        foreach ($line in $promoPopupBody) {
            Assert-Contains $homeHtml $line 'index.html promo popup fallback body'
        }
        foreach ($line in $promoPopupBullets) {
            Assert-Contains $homeHtml $line 'index.html promo popup fallback bullets'
        }
        Assert-Contains $homeHtml $promoPopupCtaLabel 'index.html promo popup fallback CTA'
        Assert-Contains $homeHtml $promoPopupCtaUrl 'index.html promo popup fallback CTA URL'
    }
}
elseif ($promoPopupEnabled -eq $false) {
    Assert-NotMatches $homeHtml '(?is)<div\b[^>]*data-promo-popup="root"' 'index.html promo popup root'
    Assert-NotMatches $homeHtml '(?is)<button\b[^>]*data-promo-popup="backdrop"' 'index.html promo popup backdrop'
    Assert-NotMatches $homeHtml '(?is)<button\b[^>]*data-promo-popup="close"' 'index.html promo popup close'
}
else {
    Add-Problem 'Unable to determine popup enabled state from data/promo-popup.toml'
}

# Issue 12: models pages must render the richer showcase variant.
Assert-Matches $bikeModelsHtml '(?is)\bmedia-collection--showcase\b' 'bikeshop/modellen-in-de-kijker/index.html showcase variant'
Assert-Matches $driveModelsHtml '(?is)\bmedia-collection--showcase\b' 'driveshop/modellen-in-de-kijker/index.html showcase variant'
Assert-Matches $bikeModelsHtml '(?is)\bmedia-showcase__intro\b' 'bikeshop/modellen-in-de-kijker/index.html showcase intro'
Assert-Matches $driveModelsHtml '(?is)\bmedia-showcase__intro\b' 'driveshop/modellen-in-de-kijker/index.html showcase intro'
Assert-Matches $bikeModelsHtml '(?is)\bmedia-showcase__specs\b' 'bikeshop/modellen-in-de-kijker/index.html showcase specs'
Assert-Matches $driveModelsHtml '(?is)\bmedia-showcase__specs\b' 'driveshop/modellen-in-de-kijker/index.html showcase specs'
Assert-Matches $cssContent '(?is)\.media-collection--showcase\b' 'assets/css/style.css showcase collection CSS hook'
Assert-Matches $cssContent '(?is)\.media-showcase__image\b[^{}]*\{[^}]*aspect-ratio\s*:\s*4\s*/\s*3' 'assets/css/style.css showcase uniform image ratio'
Assert-Matches $cssContent '(?is)\.media-showcase__item\b[^{}]*\{[^}]*grid-template-columns\s*:\s*1fr\s+1fr' 'assets/css/style.css showcase equal width columns'
Assert-Matches $cssContent '(?is)\.media-showcase__item--reverse\b' 'assets/css/style.css alternating showcase CSS hook'

# Issue 11: footer and contact page must share the same core contact data.
Assert-Matches $homeFooterSection '(?is)\bsite-footer__contact\b' 'index.html footer contact column'
Assert-NotContains $homeFooterSection 'site-footer__contact-term' 'index.html footer contact titles removed'

if (-not [string]::IsNullOrWhiteSpace($sharedContactAddress)) {
    Assert-Contains $homeFooterSection $sharedContactAddress 'index.html footer address'
    Assert-Contains $contactHtml $sharedContactAddress 'contact/index.html shared address'
}

if (-not [string]::IsNullOrWhiteSpace($sharedContactEmail)) {
    Assert-Contains $homeFooterSection $sharedContactEmail 'index.html footer email'
    Assert-Contains $contactHtml $sharedContactEmail 'contact/index.html shared email'
}

if (-not [string]::IsNullOrWhiteSpace($sharedContactPhone)) {
    Assert-Contains $homeFooterSection $sharedContactPhone 'index.html footer phone'
    Assert-Contains $contactHtml $sharedContactPhone 'contact/index.html shared phone'
}

if (-not [string]::IsNullOrWhiteSpace($sharedContactName)) {
    Assert-Contains $contactHtml $sharedContactName 'contact/index.html shared name'
}

if ($problems.Count -gt 0) {
    Write-Error ($problems -join "`n")
    exit 1
}

Write-Host 'All site verification checks passed.'



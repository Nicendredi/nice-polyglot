#!/usr/bin/env pwsh
#Requires -Version 7.0

# resolve-language-policy.ps1
#
# Resolves the effective Nice Polyglot language policy by merging up to three YAML config
# layers (extension -> project -> user) and emitting a structured sentinel block to stdout.
#
# Config layer paths (relative to .specify root):
#   Extension : extensions/nice-polyglot/nice-polyglot-config.yml
#   Project   : overrides/nice-polyglot-config.yml
#   User      : .nice-polyglot/{user}-config.yml
#
# All three layers are optional.  When none is present the script uses hardcoded defaults
# (all categories "en", accepted_languages: [en]).
#
# Exit codes:
#   0 - policy resolved successfully (warnings for skipped layers go to stderr)
#   1 - fatal error (common.ps1 not found or no .specify root located)

# ---------------------------------------------------------------------------
# Bootstrap: locate the .specify root and dot-source common.ps1
# ---------------------------------------------------------------------------
function _NP_FindSpecifyRoot {
    param([string]$StartDir)
    $resolved = Resolve-Path -LiteralPath $StartDir -ErrorAction SilentlyContinue
    $current  = if ($resolved) { $resolved.Path } else { return $null }
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current '.specify') -PathType Container) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) { return $null }
        $current = $parent
    }
}

$_npBootstrapRoot = _NP_FindSpecifyRoot -StartDir $PSScriptRoot
if (-not $_npBootstrapRoot) {
    $_npBootstrapRoot = _NP_FindSpecifyRoot -StartDir (Get-Location).Path
}
if (-not $_npBootstrapRoot) {
    [System.Console]::Error.WriteLine('[nice-polyglot] ERROR: Cannot find .specify root. Is this a SpecKit project?')
    exit 1
}

$_npCommonPsPath = Join-Path $_npBootstrapRoot '.specify' 'scripts' 'powershell' 'common.ps1'
if (-not (Test-Path -LiteralPath $_npCommonPsPath)) {
    [System.Console]::Error.WriteLine("[nice-polyglot] ERROR: common.ps1 not found at '$_npCommonPsPath'. Is SpecKit installed?")
    exit 1
}

try {
    . $_npCommonPsPath
} catch {
    [System.Console]::Error.WriteLine("[nice-polyglot] ERROR: Failed to load common.ps1: $_")
    exit 1
}

$_npRepoRoot = Get-RepoRoot
if (-not $_npRepoRoot) {
    [System.Console]::Error.WriteLine('[nice-polyglot] ERROR: Get-RepoRoot returned null. Cannot locate .specify root.')
    exit 1
}

$_npSpecifyRoot = Join-Path $_npRepoRoot '.specify'

# ---------------------------------------------------------------------------
# Internal helper: write a message to stderr
# ---------------------------------------------------------------------------
function _NP_WriteStderr {
    param([string]$Message)
    [System.Console]::Error.WriteLine($Message)
}

# ---------------------------------------------------------------------------
# Get-UserIdentifier
#
# Derives the {user} component of the user-layer config filename.
#   1. git config user.email   - sanitised: @ -> -at-,  . -> -,  lowercased
#   2. $env:USERNAME            - Windows
#   3. $env:USER                - macOS / Linux
#   4. literal "unknown"        - fallback (writes warning to stderr)
# ---------------------------------------------------------------------------
function Get-UserIdentifier {
    try {
        $email = (& git config user.email 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($email)) {
            return ($email.Trim() -replace '@', '-at-' -replace '\.', '-').ToLower()
        }
    } catch { <# git unavailable #> }

    if (-not [string]::IsNullOrWhiteSpace($env:USERNAME)) { return $env:USERNAME }
    if (-not [string]::IsNullOrWhiteSpace($env:USER))     { return $env:USER }

    _NP_WriteStderr '[nice-polyglot] WARNING: Could not determine user identity; using "unknown" for config path.'
    return 'unknown'
}

# ---------------------------------------------------------------------------
# Parse-NicePolyglotConfig
#
# Parses a single YAML config file that conforms to the nice-polyglot schema.
# No external YAML dependencies - uses line-by-line parsing.
#
# Returns a hashtable with:
#   schema_version     : string or $null
#   accepted_languages : string[]
#   language_settings  : hashtable (category -> code)
#
# Returns $null if the file does not exist or cannot be read/parsed.
# ---------------------------------------------------------------------------
function Parse-NicePolyglotConfig {
    param([string]$filePath)

    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) { return $null }

    try {
        $lines = Get-Content -LiteralPath $filePath -Encoding UTF8 -ErrorAction Stop
    } catch {
        return $null
    }

    $result = @{
        schema_version     = $null
        accepted_languages = [System.Collections.Generic.List[string]]::new()
        language_settings  = @{}
    }

    $state = 'NONE'

    try {
        foreach ($line in $lines) {
            $trimmed = $line.TrimEnd()

            # Skip blank lines and comment-only lines
            if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed -match '^\s*#') { continue }

            # Detect top-level keys: no leading whitespace, format "key: value"
            # Use single-quoted regex strings to avoid PowerShell variable expansion of $
            if ($trimmed -match '^([a-z][a-z_-]*):\s*(.*)$') {
                $key    = $Matches[1]
                $rawVal = $Matches[2].Trim().Trim([char]0x27, [char]0x22)   # strip surrounding ' and "
                switch ($key) {
                    'schema_version'     { $result['schema_version'] = $rawVal; $state = 'NONE' }
                    'accepted_languages' { $state = 'IN_ACCEPTED_LANGUAGES' }
                    'language_settings'  { $state = 'IN_LANGUAGE_SETTINGS' }
                    default              { $state = 'NONE' }
                }
                continue
            }

            # accepted_languages list items:  "  - code"
            if ($state -eq 'IN_ACCEPTED_LANGUAGES' -and $trimmed -match '^\s*-\s+(\S+)') {
                $code = $Matches[1].Trim([char]0x27, [char]0x22)
                $result['accepted_languages'].Add($code) | Out-Null
                continue
            }

            # language_settings key-value pairs:  "  key: value"
            if ($state -eq 'IN_LANGUAGE_SETTINGS' -and $trimmed -match '^\s+([a-z][a-z-]*):\s*(.+)$') {
                $k = $Matches[1].Trim()
                $v = $Matches[2].Trim().Trim([char]0x27, [char]0x22)
                if (-not [string]::IsNullOrWhiteSpace($v)) {
                    $result['language_settings'][$k] = $v
                }
                continue
            }
        }
    } catch {
        return $null
    }

    $result['accepted_languages'] = @($result['accepted_languages'])
    return $result
}

# ---------------------------------------------------------------------------
# Load-ConfigLayer
#
# Wraps Parse-NicePolyglotConfig with layer-level error handling.
#
# Returns: parsed config hashtable, or $null when the layer is absent/invalid.
# ---------------------------------------------------------------------------
function Load-ConfigLayer {
    param([string]$path, [string]$layerName)

    # Optional layer absent - silent null
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }

    $parsed = Parse-NicePolyglotConfig -filePath $path
    if ($null -eq $parsed) {
        _NP_WriteStderr "[nice-polyglot] WARNING: Could not read $path. Using settings from lower-precedence layers."
        return $null
    }

    # schema_version check (design constraint - no user-visible effect in v1.0)
    $sv = $parsed['schema_version']
    if (-not [string]::IsNullOrWhiteSpace($sv) -and $sv -ne '1.0') {
        _NP_WriteStderr "[nice-polyglot] WARNING: Layer '$layerName' has unsupported schema_version '$sv'. Proceeding with available fields."
    }

    return $parsed
}

# ---------------------------------------------------------------------------
# Merge-ConfigLayers
#
# Executes the 3-layer merge algorithm (data-model.md Merge Algorithm) and
# enforces validation rules V-001 through V-008.
#
# Parameters : $extension, $project, $user  - output of Load-ConfigLayer (hashtable or $null)
# Returns    : ordered hashtable representing the EffectiveLanguagePolicy
# ---------------------------------------------------------------------------
function Merge-ConfigLayers {
    param($extension, $project, $user)

    # Shared file-output categories constrained by accepted_languages (7 total)
    $sharedCategories = @(
        'artifacts', 'documentation', 'code', 'code-comments',
        'log-messages', 'internal-docs', 'commit-messages'
    )
    $allCategories = @('interactions') + $sharedCategories

    # Step 1 - Start with hardcoded defaults
    $working = [ordered]@{
        accepted_languages = @('en')
        interactions       = 'en'
        artifacts          = 'en'
        documentation      = 'en'
        code               = 'en'
        'code-comments'    = 'en'
        'log-messages'     = 'en'
        'internal-docs'    = 'en'
        'commit-messages'  = 'en'
    }

    $layerEntries = @(
        [pscustomobject]@{ Layer = $extension; Name = 'extension'; IsUser = $false }
        [pscustomobject]@{ Layer = $project;   Name = 'project';   IsUser = $false }
        [pscustomobject]@{ Layer = $user;       Name = 'user';      IsUser = $true  }
    )

    foreach ($entry in $layerEntries) {
        $layer     = $entry.Layer
        $layerName = $entry.Name
        $isUser    = $entry.IsUser

        # a. Skip null layers
        if ($null -eq $layer) { continue }

        $layerAL = $layer['accepted_languages']
        $layerLS = $layer['language_settings']

        # b. User layer: ignore accepted_languages if present (V-005)
        if ($isUser -and $layerAL -and $layerAL.Count -gt 0) {
            _NP_WriteStderr '[nice-polyglot] WARNING: accepted_languages in user override is ignored (V-005). Set accepted_languages at the project layer instead.'
        }

        # c. Non-user layers: validate accepted_languages codes (V-002)
        if (-not $isUser -and $layerAL -and $layerAL.Count -gt 0) {
            $badCodes = @($layerAL | Where-Object { $_ -notmatch '^[a-z]{2}$' })
            if ($badCodes.Count -gt 0) {
                _NP_WriteStderr "[nice-polyglot] WARNING: Layer '$layerName' contains invalid accepted_languages codes: [$($badCodes -join ', ')]. Layer discarded (V-002)."
                continue
            }
        }

        # d. Tentatively apply accepted_languages for non-user layers (with en guarantee)
        $savedAccepted = $working['accepted_languages']
        if (-not $isUser -and $layerAL -and $layerAL.Count -gt 0) {
            $tentative = @($layerAL)
            if ('en' -notin $tentative) { $tentative += 'en' }
            $working['accepted_languages'] = $tentative
        }

        # e. Validate interactions (V-004) - must be a valid two-letter lowercase code
        if ($layerLS -and $layerLS.ContainsKey('interactions')) {
            $intVal = $layerLS['interactions']
            if ($intVal -notmatch '^[a-z]{2}$') {
                _NP_WriteStderr "[nice-polyglot] WARNING: Layer '$layerName' has invalid interactions value '$intVal'. Layer discarded (V-004)."
                $working['accepted_languages'] = $savedAccepted
                continue
            }
        }

        # f. Validate shared file-output categories against current accepted_languages (V-003)
        if ($layerLS) {
            $layerInvalid = $false
            foreach ($cat in $sharedCategories) {
                if ($layerLS.ContainsKey($cat)) {
                    $val = $layerLS[$cat]
                    if ($val -notin $working['accepted_languages']) {
                        _NP_WriteStderr "[nice-polyglot] WARNING: Layer '$layerName' has '${cat}: $val' which is not in accepted_languages [$($working['accepted_languages'] -join ', ')]. Layer discarded (V-003)."
                        $layerInvalid = $true
                        break
                    }
                }
            }
            if ($layerInvalid) {
                $working['accepted_languages'] = $savedAccepted
                continue
            }
        }

        # g. Layer is fully valid - commit all values
        if ($layerLS) {
            foreach ($cat in $allCategories) {
                if ($layerLS.ContainsKey($cat)) {
                    $working[$cat] = $layerLS[$cat]
                }
            }
        }
    }

    # V-001: ensure accepted_languages is never empty
    if (-not $working['accepted_languages'] -or $working['accepted_languages'].Count -eq 0) {
        $working['accepted_languages'] = @('en')
    }

    return $working
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Construct config layer paths
$_npUser        = Get-UserIdentifier
$_npExtPath     = Join-Path $_npSpecifyRoot 'extensions' 'nice-polyglot' 'nice-polyglot-config.yml'
$_npProjectPath = Join-Path $_npSpecifyRoot 'overrides' 'nice-polyglot-config.yml'
$_npUserPath    = Join-Path $_npSpecifyRoot '.nice-polyglot' "$_npUser-config.yml"

# Load each layer
$_npExtLayer     = Load-ConfigLayer -path $_npExtPath     -layerName 'extension'
$_npProjectLayer = Load-ConfigLayer -path $_npProjectPath -layerName 'project'
$_npUserLayer    = Load-ConfigLayer -path $_npUserPath    -layerName 'user'

# Merge layers
$_npPolicy = Merge-ConfigLayers -extension $_npExtLayer -project $_npProjectLayer -user $_npUserLayer

# Emit structured output block (stdout only; warnings are on stderr)
$_npAcceptedStr = $_npPolicy['accepted_languages'] -join ','
[System.Console]::Out.WriteLine('NICE_POLYGLOT_POLICY_START')
[System.Console]::Out.WriteLine("accepted_languages: $_npAcceptedStr")
[System.Console]::Out.WriteLine("interactions: $($_npPolicy['interactions'])")
[System.Console]::Out.WriteLine("artifacts: $($_npPolicy['artifacts'])")
[System.Console]::Out.WriteLine("documentation: $($_npPolicy['documentation'])")
[System.Console]::Out.WriteLine("code: $($_npPolicy['code'])")
[System.Console]::Out.WriteLine("code-comments: $($_npPolicy['code-comments'])")
[System.Console]::Out.WriteLine("log-messages: $($_npPolicy['log-messages'])")
[System.Console]::Out.WriteLine("internal-docs: $($_npPolicy['internal-docs'])")
[System.Console]::Out.WriteLine("commit-messages: $($_npPolicy['commit-messages'])")
[System.Console]::Out.WriteLine('NICE_POLYGLOT_POLICY_END')

exit 0

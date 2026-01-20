<#
.SYNOPSIS
    Awesome Statusline for Claude Code - FULL Mode (Windows PowerShell)
.DESCRIPTION
    Catppuccin-themed statusline with detailed 5-line layout, 40-block progress bars
    Port of awesome-statusline v2.1.0 for Windows
.NOTES
    Version: 2.1.0-win
    Layout: 5 lines
    Bar Size: 40 blocks
#>

param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$InputJson
)

# Read JSON from stdin if not provided as parameter
if (-not $InputJson) {
    $InputJson = $input | Out-String
}

# Parse JSON input
try {
    $data = $InputJson | ConvertFrom-Json
} catch {
    Write-Output "Error parsing JSON"
    exit 1
}

# Extract values from JSON
$modelObj = $data.model
$modelId = if ($modelObj.id) { $modelObj.id } else { $modelObj }
$cwd = $data.cwd
$contextWindow = $data.context_window
$outputStyle = if ($data.output_style.name) { $data.output_style.name } elseif ($data.output_style) { $data.output_style } else { "normal" }

# Catppuccin Mocha Colors (ANSI 256-color RGB)
$ESC = [char]27

# Base colors
$TEAL = "$ESC[38;2;148;226;213m"
$PINK = "$ESC[38;2;245;194;231m"
$PEACH = "$ESC[38;2;250;179;135m"
$GREEN = "$ESC[38;2;166;227;161m"
$YELLOW = "$ESC[38;2;249;226;175m"
$LAVENDER = "$ESC[38;2;180;190;254m"
$BLUE = "$ESC[38;2;137;180;250m"
$RED = "$ESC[38;2;243;139;168m"
$MAROON = "$ESC[38;2;235;160;172m"
$MAUVE = "$ESC[38;2;203;166;247m"
$SURFACE0 = "$ESC[38;2;49;50;68m"
$SURFACE1 = "$ESC[38;2;69;71;90m"
$SUBTEXT0 = "$ESC[38;2;166;173;200m"
$SUBTEXT1 = "$ESC[38;2;186;194;222m"
$TEXT = "$ESC[38;2;205;214;244m"
$RESET = "$ESC[0m"
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"

# Gradient colors
$MOCHA_MAROON = "$ESC[38;2;235;160;172m"
$LATTE_MAROON = "$ESC[38;2;220;138;120m"

# Function: Get context gradient color
function Get-ContextGradientColor {
    param([double]$percent)
    if ($percent -lt 40) { return $MOCHA_MAROON }
    elseif ($percent -lt 80) { return $LATTE_MAROON }
    else { return $RED }
}

# Function: Get 5H gradient color
function Get-Usage5HGradientColor {
    param([double]$percent)
    if ($percent -lt 50) { return $LAVENDER }
    elseif ($percent -lt 80) { return $BLUE }
    else { return $RED }
}

# Function: Get 7D gradient color
function Get-Usage7DGradientColor {
    param([double]$percent)
    if ($percent -lt 50) { return $YELLOW }
    elseif ($percent -lt 80) { return $GREEN }
    else { return $RED }
}

# Function: Generate progress bar (ASCII, 40 chars for full mode)
function Get-ProgressBar {
    param(
        [double]$percent,
        [int]$width = 40,
        [string]$fillColor,
        [string]$emptyColor = $SURFACE0
    )

    $filled = [math]::Floor($percent / 100 * $width)
    $empty = $width - $filled

    $fillChar = "="
    $emptyChar = "-"

    return "[$fillColor" + ($fillChar * $filled) + "$emptyColor" + ($emptyChar * $empty) + "$RESET]"
}

# Function: Get detailed Git info
function Get-GitInfoFull {
    $gitInfo = @{
        branch = ""
        isDirty = $false
        ahead = 0
        behind = 0
        statusIcon = ""
    }

    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            $gitInfo.branch = $branch

            # Check dirty status
            $status = git status --porcelain 2>$null
            if ($status) {
                $gitInfo.isDirty = $true
                $gitInfo.statusIcon = "${YELLOW}*${RESET}"
            } else {
                $gitInfo.statusIcon = ""
            }

            # Get ahead/behind
            $tracking = git rev-parse --abbrev-ref "@{upstream}" 2>$null
            if ($LASTEXITCODE -eq 0 -and $tracking) {
                $aheadBehind = git rev-list --left-right --count HEAD..."@{upstream}" 2>$null
                if ($LASTEXITCODE -eq 0 -and $aheadBehind) {
                    $parts = $aheadBehind -split '\s+'
                    $gitInfo.ahead = [int]$parts[0]
                    $gitInfo.behind = [int]$parts[1]
                }
            }
        }
    } catch { }

    return $gitInfo
}

# Function: Shorten path
function Get-ShortPath {
    param([string]$path)

    $homePath = $env:USERPROFILE
    if ($path.StartsWith($homePath)) {
        $path = "~" + $path.Substring($homePath.Length)
    }

    if ($path.Length -gt 40) {
        $parts = $path -split '[/\\]'
        if ($parts.Count -gt 3) {
            $path = $parts[0] + "/.../" + $parts[-2] + "/" + $parts[-1]
        }
    }

    return $path.Replace('\', '/')
}

# Function: Format model name (full)
function Get-ModelDisplay {
    param([string]$model)

    switch -Regex ($model) {
        "opus" { return "${MAUVE}${BOLD}Opus 4.5${RESET}" }
        "sonnet" { return "${BLUE}${BOLD}Sonnet 4${RESET}" }
        "haiku" { return "${GREEN}${BOLD}Haiku${RESET}" }
        default { return "${TEXT}${BOLD}$model${RESET}" }
    }
}

# Function: Format tokens
function Format-Tokens {
    param([int]$tokens)

    if ($tokens -ge 1000000) {
        return "{0:N1}M" -f ($tokens / 1000000)
    } elseif ($tokens -ge 1000) {
        return "{0:N1}K" -f ($tokens / 1000)
    }
    return $tokens.ToString()
}

# Function: Get Claude usage data from API
function Get-ClaudeUsage {
    $cacheFile = "$env:TEMP\.claude_usage_cache"
    $cacheMaxAge = 300  # 5 minutes

    if (Test-Path $cacheFile) {
        $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        if ($cacheAge.TotalSeconds -lt $cacheMaxAge) {
            try { return Get-Content $cacheFile -Raw | ConvertFrom-Json } catch { }
        }
    }

    $credFile = "$env:USERPROFILE\.claude\.credentials.json"
    if (-not (Test-Path $credFile)) {
        return @{ five_hour = @{ utilization = 0; resets_at = "" }; seven_day = @{ utilization = 0; resets_at = "" } }
    }

    try {
        $creds = Get-Content $credFile -Raw | ConvertFrom-Json
        $token = $creds.claudeAiOauth.accessToken
        if (-not $token) { return @{ five_hour = @{ utilization = 0 }; seven_day = @{ utilization = 0 } } }

        $headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json"; "anthropic-beta" = "oauth-2025-04-20" }
        $response = Invoke-RestMethod -Uri "https://api.anthropic.com/api/oauth/usage" -Headers $headers -Method Get -TimeoutSec 5
        $response | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Force
        return $response
    } catch {
        if (Test-Path $cacheFile) { try { return Get-Content $cacheFile -Raw | ConvertFrom-Json } catch { } }
        return @{ five_hour = @{ utilization = 0 }; seven_day = @{ utilization = 0 } }
    }
}

# Function: Format reset time
function Get-ResetTimeDisplay {
    param([string]$resetAt)
    if (-not $resetAt) { return "" }
    try {
        $resetTime = [DateTime]::Parse($resetAt)
        $diff = $resetTime - (Get-Date)
        if ($diff.TotalHours -lt 1) { return "$([math]::Floor($diff.TotalMinutes))m" }
        elseif ($diff.TotalDays -lt 1) { return "$([math]::Floor($diff.TotalHours))h" }
        return "$([math]::Floor($diff.TotalDays))d"
    } catch { return "" }
}

# Calculate context usage - use used_percentage directly from Claude Code
$contextPercent = if ($contextWindow.used_percentage) {
    [math]::Round($contextWindow.used_percentage, 1)
} else {
    0
}

# Get actual usage data from API
$usageData = Get-ClaudeUsage
$usage5H = @{
    percent = [math]::Round($usageData.five_hour.utilization, 1)
    resetTime = Get-ResetTimeDisplay $usageData.five_hour.resets_at
}
$usage7D = @{
    percent = [math]::Round($usageData.seven_day.utilization, 1)
    resetDay = Get-ResetTimeDisplay $usageData.seven_day.resets_at
}

# Get session duration (placeholder)
$sessionStart = Get-Date
$sessionDuration = "0m"

# Get git info
$gitInfo = Get-GitInfoFull

# Format display values
$modelDisplay = Get-ModelDisplay $modelId
$shortPath = Get-ShortPath $cwd
$styleDisplay = "${DIM}($outputStyle)${RESET}"

# Generate bars (40 blocks for full mode)
$contextColor = Get-ContextGradientColor $contextPercent
$contextBar = Get-ProgressBar -percent $contextPercent -width 40 -fillColor $contextColor

$usage5HColor = Get-Usage5HGradientColor $usage5H.percent
$usage5HBar = Get-ProgressBar -percent $usage5H.percent -width 40 -fillColor $usage5HColor

$usage7DColor = Get-Usage7DGradientColor $usage7D.percent
$usage7DBar = Get-ProgressBar -percent $usage7D.percent -width 40 -fillColor $usage7DColor

# ============================================
# LINE 1: Model | Style | Git Status | Env
# ============================================
$line1Parts = @()
$line1Parts += "$modelDisplay"
$line1Parts += "$styleDisplay"

if ($gitInfo.branch) {
    $gitStatus = "${GREEN}Git${RESET}"
    if ($gitInfo.ahead -gt 0) {
        $gitStatus += " ${GREEN}+$($gitInfo.ahead)${RESET}"
    }
    if ($gitInfo.behind -gt 0) {
        $gitStatus += " ${RED}-$($gitInfo.behind)${RESET}"
    }
    $line1Parts += $gitStatus
}

# Conda/venv detection
$envName = ""
if ($env:CONDA_DEFAULT_ENV) {
    $envName = "${GREEN}py:$($env:CONDA_DEFAULT_ENV)${RESET}"
} elseif ($env:VIRTUAL_ENV) {
    $venvName = Split-Path $env:VIRTUAL_ENV -Leaf
    $envName = "${GREEN}py:$venvName${RESET}"
}
if ($envName) { $line1Parts += $envName }

$line1 = $line1Parts -join " ${DIM}|${RESET} "

# ============================================
# LINE 2: Path | Branch | Cost | Duration
# ============================================
$line2Parts = @()
$line2Parts += "${TEAL}$shortPath${RESET}"

if ($gitInfo.branch) {
    $branchDisplay = "${GREEN}git:${RESET}${SUBTEXT0}($($gitInfo.branch))${RESET}$($gitInfo.statusIcon)"
    $line2Parts += $branchDisplay
}

# Cost tracking (placeholder)
$line2Parts += "${GREEN}`$0.00${RESET}"

# Session duration
$line2Parts += "${SUBTEXT0}$sessionDuration${RESET}"

$line2 = $line2Parts -join " ${DIM}|${RESET} "

# ============================================
# LINE 3: Context Window Bar
# ============================================
$contextUsedDisplay = Format-Tokens $contextUsed
$contextTotalDisplay = Format-Tokens $contextTotal
$line3 = "${PINK}Ctx:${RESET} $contextBar ${BOLD}$contextColor$contextPercent%${RESET} ${DIM}($contextUsedDisplay / $contextTotalDisplay)${RESET}"

# ============================================
# LINE 4: 5H Limit Bar
# ============================================
$reset5HDisplay = if ($usage5H.resetTime) { " ${DIM}reset: $($usage5H.resetTime)${RESET}" } else { "" }
$line4 = "${LAVENDER}5H:${RESET}  $usage5HBar ${BOLD}$usage5HColor$($usage5H.percent)%${RESET}$reset5HDisplay"

# ============================================
# LINE 5: 7D Limit Bar
# ============================================
$reset7DDisplay = if ($usage7D.resetDay) { " ${DIM}reset: $($usage7D.resetDay)${RESET}" } else { "" }
$line5 = "${YELLOW}7D:${RESET}  $usage7DBar ${BOLD}$usage7DColor$($usage7D.percent)%${RESET}$reset7DDisplay"

# Output all 5 lines
Write-Output $line1
Write-Output $line2
Write-Output $line3
Write-Output $line4
Write-Output $line5

<#
.SYNOPSIS
    Awesome Statusline for Claude Code - DEFAULT Mode (Windows PowerShell)
.DESCRIPTION
    Catppuccin-themed statusline with 2-line layout, 10-block progress bars
    Port of awesome-statusline v2.1.0 for Windows
.NOTES
    Version: 2.1.0-win
    Layout: 2 lines
    Bar Size: 10 blocks
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
$SUBTEXT0 = "$ESC[38;2;166;173;200m"
$TEXT = "$ESC[38;2;205;214;244m"
$RESET = "$ESC[0m"
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"

# Gradient colors for context (Pink -> Red)
$MOCHA_MAROON = "$ESC[38;2;235;160;172m"
$LATTE_MAROON = "$ESC[38;2;220;138;120m"

# Function: Get context gradient color based on percentage
function Get-ContextGradientColor {
    param([double]$percent)

    if ($percent -lt 40) { return $MOCHA_MAROON }
    elseif ($percent -lt 80) { return $LATTE_MAROON }
    else { return $RED }
}

# Function: Get 5H usage gradient color (Lavender -> Blue -> Red)
function Get-Usage5HGradientColor {
    param([double]$percent)

    if ($percent -lt 50) { return $LAVENDER }
    elseif ($percent -lt 80) { return $BLUE }
    else { return $RED }
}

# Function: Get 7D usage gradient color (Yellow -> Green -> Red)
function Get-Usage7DGradientColor {
    param([double]$percent)

    if ($percent -lt 50) { return $YELLOW }
    elseif ($percent -lt 80) { return $GREEN }
    else { return $RED }
}

# Function: Generate progress bar (ASCII)
function Get-ProgressBar {
    param(
        [double]$percent,
        [int]$width = 10,
        [string]$fillColor,
        [string]$emptyColor = $SURFACE0
    )

    $filled = [math]::Floor($percent / 100 * $width)
    $empty = $width - $filled

    $fillChar = "="
    $emptyChar = "-"

    return "[$fillColor" + ($fillChar * $filled) + "$emptyColor" + ($emptyChar * $empty) + "$RESET]"
}

# Function: Get Git info
function Get-GitInfo {
    $gitInfo = @{
        branch = ""
        isDirty = $false
        icon = ""
    }

    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            $gitInfo.branch = $branch

            $status = git status --porcelain 2>$null
            if ($status) {
                $gitInfo.isDirty = $true
                $gitInfo.icon = "${YELLOW}*${RESET}"
            } else {
                $gitInfo.icon = ""
            }
        }
    } catch {
        # Not a git repo or git not available
    }

    return $gitInfo
}

# Function: Shorten path
function Get-ShortPath {
    param([string]$path)

    $homePath = $env:USERPROFILE
    if ($path.StartsWith($homePath)) {
        $path = "~" + $path.Substring($homePath.Length)
    }

    # Shorten if too long (max 30 chars)
    if ($path.Length -gt 30) {
        $parts = $path -split '[/\\]'
        if ($parts.Count -gt 3) {
            $path = $parts[0] + "/.../" + $parts[-2] + "/" + $parts[-1]
        }
    }

    return $path.Replace('\', '/')
}

# Function: Format model name
function Get-ModelDisplay {
    param([string]$model)

    switch -Regex ($model) {
        "opus" { return "${MAUVE}Opus 4.5${RESET}" }
        "sonnet" { return "${BLUE}Sonnet 4${RESET}" }
        "haiku" { return "${GREEN}Haiku${RESET}" }
        default { return "${TEXT}$model${RESET}" }
    }
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
        return "$([math]::Floor($diff.TotalHours))h"
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

# Get git info
$gitInfo = Get-GitInfo

# Format display values
$modelDisplay = Get-ModelDisplay $modelId
$shortPath = Get-ShortPath $cwd
$styleDisplay = "${DIM}($outputStyle)${RESET}"

# Generate progress bars
$contextColor = Get-ContextGradientColor $contextPercent
$contextBar = Get-ProgressBar -percent $contextPercent -width 10 -fillColor $contextColor

$usage5HColor = Get-Usage5HGradientColor $usage5H.percent
$usage5HBar = Get-ProgressBar -percent $usage5H.percent -width 10 -fillColor $usage5HColor

$usage7DColor = Get-Usage7DGradientColor $usage7D.percent
$usage7DBar = Get-ProgressBar -percent $usage7D.percent -width 10 -fillColor $usage7DColor

# Build Line 1: Model | Style | Path | Git
$line1Parts = @()
$line1Parts += "$modelDisplay"
$line1Parts += "$styleDisplay"

if ($shortPath) {
    $line1Parts += "${TEAL}$shortPath${RESET}"
}

if ($gitInfo.branch) {
    $line1Parts += "${GREEN}git:${RESET}${SUBTEXT0}($($gitInfo.branch))${RESET}$($gitInfo.icon)"
}

$line1 = $line1Parts -join " ${DIM}|${RESET} "

# Build Line 2: Context Bar | 5H Bar | 7D Bar (ASCII labels)
$contextDisplay = "${PINK}Ctx${RESET} $contextBar ${BOLD}$contextColor$contextPercent%${RESET}"

$line2Parts = @()
$line2Parts += $contextDisplay

if ($usage5H.percent -gt 0 -or $usage5H.resetTime) {
    $usage5HDisplay = "${LAVENDER}5H${RESET} $usage5HBar ${BOLD}$usage5HColor$($usage5H.percent)%${RESET}"
    if ($usage5H.resetTime) {
        $usage5HDisplay += " ${DIM}$($usage5H.resetTime)${RESET}"
    }
    $line2Parts += $usage5HDisplay
}

if ($usage7D.percent -gt 0 -or $usage7D.resetDay) {
    $usage7DDisplay = "${YELLOW}7D${RESET} $usage7DBar ${BOLD}$usage7DColor$($usage7D.percent)%${RESET}"
    if ($usage7D.resetDay) {
        $usage7DDisplay += " ${DIM}$($usage7D.resetDay)${RESET}"
    }
    $line2Parts += $usage7DDisplay
}

$line2 = $line2Parts -join " ${DIM}|${RESET} "

# Output
Write-Output $line1
Write-Output $line2

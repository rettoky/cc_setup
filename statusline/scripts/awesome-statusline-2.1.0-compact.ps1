<#
.SYNOPSIS
    Awesome Statusline for Claude Code - COMPACT Mode (Windows PowerShell)
.DESCRIPTION
    Catppuccin-themed statusline with minimal 2-line layout
    Port of awesome-statusline v2.1.0 for Windows
.NOTES
    Version: 2.1.0-win
    Layout: 2 lines (minimal)
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

# Catppuccin Mocha Colors (ANSI 256-color RGB)
$ESC = [char]27

# Base colors
$TEAL = "$ESC[38;2;148;226;213m"
$PINK = "$ESC[38;2;245;194;231m"
$GREEN = "$ESC[38;2;166;227;161m"
$YELLOW = "$ESC[38;2;249;226;175m"
$LAVENDER = "$ESC[38;2;180;190;254m"
$BLUE = "$ESC[38;2;137;180;250m"
$RED = "$ESC[38;2;243;139;168m"
$MAUVE = "$ESC[38;2;203;166;247m"
$SURFACE0 = "$ESC[38;2;49;50;68m"
$SUBTEXT0 = "$ESC[38;2;166;173;200m"
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

# Function: Get Git branch only (minimal)
function Get-GitBranch {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            $status = git status --porcelain 2>$null
            $icon = if ($status) { "${YELLOW}*${RESET}" } else { "" }
            return "${GREEN}git:${RESET}${DIM}($branch)${RESET}$icon"
        }
    } catch { }
    return ""
}

# Function: Shorten path (more aggressive for compact)
function Get-ShortPath {
    param([string]$path)

    $homePath = $env:USERPROFILE
    if ($path.StartsWith($homePath)) {
        $path = "~" + $path.Substring($homePath.Length)
    }

    # More aggressive shortening for compact mode (max 20 chars)
    if ($path.Length -gt 20) {
        $parts = $path -split '[/\\]'
        if ($parts.Count -gt 2) {
            $path = $parts[0] + "/.../" + $parts[-1]
        }
    }

    return $path.Replace('\', '/')
}

# Function: Get short model name
function Get-ShortModelName {
    param([string]$model)

    switch -Regex ($model) {
        "opus" { return "${MAUVE}Opus${RESET}" }
        "sonnet" { return "${BLUE}Sonnet${RESET}" }
        "haiku" { return "${GREEN}Haiku${RESET}" }
        default { return "${TEXT}$model${RESET}" }
    }
}

# Function: Get Claude usage data from API
function Get-ClaudeUsage {
    $cacheFile = "$env:TEMP\.claude_usage_cache"
    $cacheMaxAge = 300  # 5 minutes in seconds

    # Check cache
    if (Test-Path $cacheFile) {
        $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        if ($cacheAge.TotalSeconds -lt $cacheMaxAge) {
            try {
                return Get-Content $cacheFile -Raw | ConvertFrom-Json
            } catch { }
        }
    }

    # Get credentials
    $credFile = "$env:USERPROFILE\.claude\.credentials.json"
    if (-not (Test-Path $credFile)) {
        return @{ five_hour = @{ utilization = 0 }; seven_day = @{ utilization = 0 } }
    }

    try {
        $creds = Get-Content $credFile -Raw | ConvertFrom-Json
        $token = $creds.claudeAiOauth.accessToken

        if (-not $token) {
            return @{ five_hour = @{ utilization = 0 }; seven_day = @{ utilization = 0 } }
        }

        # Call API
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
            "anthropic-beta" = "oauth-2025-04-20"
        }

        $response = Invoke-RestMethod -Uri "https://api.anthropic.com/api/oauth/usage" -Headers $headers -Method Get -TimeoutSec 5

        # Cache response
        $response | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Force

        return $response
    } catch {
        # Return cached data if available, otherwise zeros
        if (Test-Path $cacheFile) {
            try {
                return Get-Content $cacheFile -Raw | ConvertFrom-Json
            } catch { }
        }
        return @{ five_hour = @{ utilization = 0 }; seven_day = @{ utilization = 0 } }
    }
}

# Calculate context usage - use used_percentage directly from Claude Code
$contextPercent = if ($contextWindow.used_percentage) {
    [math]::Round($contextWindow.used_percentage, 1)
} else {
    0
}

# Get actual usage data from API
$usageData = Get-ClaudeUsage
$usage5H = @{ percent = [math]::Round($usageData.five_hour.utilization, 1) }
$usage7D = @{ percent = [math]::Round($usageData.seven_day.utilization, 1) }

# Get display values
$modelDisplay = Get-ShortModelName $modelId
$shortPath = Get-ShortPath $cwd
$gitBranch = Get-GitBranch

# Generate bars
$contextColor = Get-ContextGradientColor $contextPercent
$contextBar = Get-ProgressBar -percent $contextPercent -width 10 -fillColor $contextColor

$usage5HColor = Get-Usage5HGradientColor $usage5H.percent
$usage5HBar = Get-ProgressBar -percent $usage5H.percent -width 10 -fillColor $usage5HColor

$usage7DColor = Get-Usage7DGradientColor $usage7D.percent
$usage7DBar = Get-ProgressBar -percent $usage7D.percent -width 10 -fillColor $usage7DColor

# Build Line 1: Model | Path | Git (minimal)
$line1Parts = @("$modelDisplay")

if ($shortPath) {
    $line1Parts += "${TEAL}$shortPath${RESET}"
}

if ($gitBranch) {
    $line1Parts += $gitBranch
}

$line1 = $line1Parts -join " ${DIM}|${RESET} "

# Build Line 2: All bars in one line (improved readability)
$line2Parts = @()
$line2Parts += "${PINK}Ctx${RESET} $contextBar ${BOLD}$contextColor$contextPercent%${RESET}"
$line2Parts += "${LAVENDER}5H${RESET} $usage5HBar ${BOLD}$usage5HColor$($usage5H.percent)%${RESET}"
$line2Parts += "${YELLOW}7D${RESET} $usage7DBar ${BOLD}$usage7DColor$($usage7D.percent)%${RESET}"
$line2 = $line2Parts -join "  ${DIM}|${RESET}  "

# Output
Write-Output $line1
Write-Output $line2

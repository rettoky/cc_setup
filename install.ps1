<#
.SYNOPSIS
    Claude Code Pro Plugins - Windows Installer
.DESCRIPTION
    Installs Claude Code plugins including agents, skills, commands, MCP servers, and statusline
.PARAMETER Components
    Comma-separated list of components to install: agents, skills, commands, mcp, statusline, claude_md, all
.PARAMETER Scope
    Installation scope: global (user-wide) or project (current directory)
.PARAMETER Force
    Skip confirmation prompts
.PARAMETER Uninstall
    Remove installed components
.EXAMPLE
    .\install.ps1 -Components all -Scope global
    .\install.ps1 -Components agents,statusline -Scope project
    .\install.ps1 -Uninstall -Components statusline
#>

param(
    [Parameter()]
    [string]$Components = "all",

    [Parameter()]
    [ValidateSet("global", "project")]
    [string]$Scope = "global",

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Uninstall,

    [Parameter()]
    [ValidateSet("compact", "default", "full")]
    [string]$StatuslineMode = "compact"
)

# Colors
$ESC = [char]27
$PINK = "$ESC[38;2;245;194;231m"
$GREEN = "$ESC[38;2;166;227;161m"
$YELLOW = "$ESC[38;2;249;226;175m"
$BLUE = "$ESC[38;2;137;180;250m"
$RED = "$ESC[38;2;243;139;168m"
$MAUVE = "$ESC[38;2;203;166;247m"
$RESET = "$ESC[0m"
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"

function Write-Header {
    Write-Host ""
    Write-Host "${MAUVE}${BOLD}============================================${RESET}"
    Write-Host "${MAUVE}${BOLD}  Claude Code Pro Plugins Installer v1.0   ${RESET}"
    Write-Host "${MAUVE}${BOLD}============================================${RESET}"
    Write-Host ""
}

function Write-Step {
    param([string]$Message, [string]$Status = "info")
    $icon = switch ($Status) {
        "success" { "${GREEN}[OK]${RESET}" }
        "error" { "${RED}[FAIL]${RESET}" }
        "warning" { "${YELLOW}[WARN]${RESET}" }
        "skip" { "${DIM}[SKIP]${RESET}" }
        default { "${BLUE}[..]${RESET}" }
    }
    Write-Host "$icon $Message"
}

function Get-Paths {
    param([string]$Scope)

    $paths = @{
        PluginRoot = $PSScriptRoot
        ClaudeHome = Join-Path $env:USERPROFILE ".claude"
    }

    if ($Scope -eq "project") {
        $paths.Target = Get-Location
        $paths.ClaudeDir = Join-Path (Get-Location) ".claude"
    } else {
        $paths.Target = $paths.ClaudeHome
        $paths.ClaudeDir = $paths.ClaudeHome
    }

    return $paths
}

function Backup-ExistingFiles {
    param([hashtable]$Paths, [string[]]$Items)

    $backupDir = Join-Path $Paths.ClaudeHome ".claude-backup"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $backupDir $timestamp

    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    $backedUp = $false
    foreach ($item in $Items) {
        $itemPath = Join-Path $Paths.ClaudeDir $item
        if (Test-Path $itemPath) {
            if (-not $backedUp) {
                New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
                $backedUp = $true
            }
            Copy-Item -Path $itemPath -Destination $backupPath -Recurse -Force
        }
    }

    if ($backedUp) {
        Write-Step "Backed up existing files to: $backupPath" "success"
    }
}

function Install-Agents {
    param([hashtable]$Paths)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing Agents...${RESET}"

    $source = Join-Path $Paths.PluginRoot ".claude\agents"
    $target = Join-Path $Paths.ClaudeDir "agents"

    if (-not (Test-Path $source)) {
        Write-Step "Agents source not found" "error"
        return
    }

    if (-not (Test-Path $target)) {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }

    $categories = Get-ChildItem -Path $source -Directory
    $totalAgents = 0

    foreach ($category in $categories) {
        $targetCategory = Join-Path $target $category.Name
        Copy-Item -Path $category.FullName -Destination $target -Recurse -Force
        $agentCount = (Get-ChildItem -Path $category.FullName -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }).Count
        $totalAgents += $agentCount
        Write-Step "  $($category.Name): $agentCount agents" "success"
    }

    Write-Step "Installed $totalAgents agents in $($categories.Count) categories" "success"
}

function Install-Skills {
    param([hashtable]$Paths)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing Skills...${RESET}"

    $source = Join-Path $Paths.PluginRoot ".claude\skills"
    $target = Join-Path $Paths.ClaudeDir "skills"

    if (-not (Test-Path $source)) {
        Write-Step "Skills source not found" "error"
        return
    }

    if (-not (Test-Path $target)) {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }

    $skills = Get-ChildItem -Path $source -Filter "*.md"
    foreach ($skill in $skills) {
        Copy-Item -Path $skill.FullName -Destination $target -Force
        Write-Step "  $($skill.Name)" "success"
    }

    Write-Step "Installed $($skills.Count) skills" "success"
}

function Install-Commands {
    param([hashtable]$Paths)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing Commands...${RESET}"

    $source = Join-Path $Paths.PluginRoot ".claude\commands"
    # Commands always go to global ~/.claude/commands
    $target = Join-Path $Paths.ClaudeHome "commands"

    if (-not (Test-Path $source)) {
        Write-Step "Commands source not found" "error"
        return
    }

    if (-not (Test-Path $target)) {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }

    $commands = Get-ChildItem -Path $source -Filter "*.md"
    foreach ($cmd in $commands) {
        Copy-Item -Path $cmd.FullName -Destination $target -Force
        Write-Step "  /$($cmd.BaseName) command" "success"
    }

    Write-Step "Installed $($commands.Count) commands" "success"
}

function Install-Templates {
    param([hashtable]$Paths)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing Templates...${RESET}"

    $source = Join-Path $Paths.PluginRoot ".claude\templates"
    $target = Join-Path $Paths.ClaudeDir "templates"

    if (-not (Test-Path $source)) {
        # Create default template
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        $templateContent = @"
# Agent Session Context

## Current Session
- **Session ID:** {SESSION_ID}
- **Started:** {DATETIME}
- **Status:** ACTIVE
- **Phase:** PLANNING

## Mission Objective
{USER_REQUEST}

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Active Team
| Role | Agent | Status |
|------|-------|--------|
| Planner | agent-organizer | Active |

## Artifact Registry
| File | Action | Agent | Notes |
|------|--------|-------|-------|

## Decision Log
| Time | Agent | Decision | Rationale |
|------|-------|----------|-----------|

## Communication
### Messages
- [Orchestrator] Session started

## Progress Tracker
### Phase 1: Planning
- [ ] Analyze requirements
- [ ] Select agents

### Phase 2: Development
- [ ] Task 1
- [ ] Task 2

### Phase 3: Review
- [ ] Code review
- [ ] Security check

## Error Log
(None)

## Handoff Notes
(None)
"@
        $templateContent | Set-Content (Join-Path $target "agents-template.md") -Force
        Write-Step "Created default session template" "success"
        return
    }

    Copy-Item -Path $source -Destination (Split-Path $target -Parent) -Recurse -Force
    Write-Step "Installed templates" "success"
}

function Install-MCP {
    param([hashtable]$Paths)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing MCP Servers...${RESET}"

    $source = Join-Path $Paths.PluginRoot ".mcp.json"
    $globalMcp = Join-Path $Paths.ClaudeHome "mcp.json"

    if (-not (Test-Path $source)) {
        Write-Step "MCP config not found" "error"
        return
    }

    $newConfig = Get-Content $source -Raw | ConvertFrom-Json

    # Merge with existing config if present
    if (Test-Path $globalMcp) {
        $existingConfig = Get-Content $globalMcp -Raw | ConvertFrom-Json
        foreach ($server in $newConfig.mcpServers.PSObject.Properties) {
            $existingConfig.mcpServers | Add-Member -NotePropertyName $server.Name -NotePropertyValue $server.Value -Force
        }
        $existingConfig | ConvertTo-Json -Depth 10 | Set-Content $globalMcp -Force
        Write-Step "Merged MCP servers into existing config" "success"
    } else {
        Copy-Item -Path $source -Destination $globalMcp -Force
        Write-Step "Created new MCP config" "success"
    }

    foreach ($server in $newConfig.mcpServers.PSObject.Properties) {
        Write-Step "  $($server.Name)" "success"
    }
}

function Install-Statusline {
    param([hashtable]$Paths, [string]$Mode)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing Statusline ($Mode mode)...${RESET}"

    $source = Join-Path $Paths.PluginRoot "plugins\awesome-statusline\scripts\awesome-statusline-2.1.0-$Mode.ps1"
    $target = Join-Path $Paths.ClaudeHome "awesome-statusline.ps1"
    $settingsPath = Join-Path $Paths.ClaudeHome "settings.json"

    if (-not (Test-Path $source)) {
        # Try alternate location
        $source = Join-Path $Paths.PluginRoot "statusline\scripts\$Mode.ps1"
    }

    if (-not (Test-Path $source)) {
        Write-Step "Statusline script not found: $source" "error"
        return
    }

    # Copy script
    Copy-Item -Path $source -Destination $target -Force
    Write-Step "Copied statusline script" "success"

    # Update settings.json
    $statuslineConfig = @{
        type = "command"
        command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$target`""
    }

    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $statuslineConfig -Force
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Force
    } else {
        @{ statusLine = $statuslineConfig } | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Force
    }

    Write-Step "Updated settings.json with statusline config" "success"
}

function Install-ClaudeMd {
    param([hashtable]$Paths)

    Write-Host ""
    Write-Host "${PINK}${BOLD}Installing CLAUDE.md...${RESET}"

    $source = Join-Path $Paths.PluginRoot "CLAUDE.md"
    $target = Join-Path $Paths.ClaudeDir "CLAUDE.md"

    if (-not (Test-Path $source)) {
        Write-Step "CLAUDE.md not found" "error"
        return
    }

    Copy-Item -Path $source -Destination $target -Force
    Write-Step "Installed CLAUDE.md" "success"
}

function Show-Summary {
    param([string[]]$Installed, [string]$Scope)

    Write-Host ""
    Write-Host "${GREEN}${BOLD}============================================${RESET}"
    Write-Host "${GREEN}${BOLD}  Installation Complete!                    ${RESET}"
    Write-Host "${GREEN}${BOLD}============================================${RESET}"
    Write-Host ""
    Write-Host "Installed components (${BLUE}$Scope${RESET}):"
    foreach ($item in $Installed) {
        Write-Host "  ${GREEN}*${RESET} $item"
    }
    Write-Host ""
    Write-Host "${YELLOW}Next steps:${RESET}"
    Write-Host "  1. Restart Claude Code to apply changes"
    Write-Host "  2. Use ${BLUE}/ag${RESET} command for multi-agent orchestration"
    Write-Host "  3. Run ${BLUE}/awesome-statusline-mode${RESET} to change statusline mode"
    Write-Host ""
}

# Main execution
Write-Header

$paths = Get-Paths -Scope $Scope
$componentList = if ($Components -eq "all") {
    @("agents", "skills", "commands", "templates", "mcp", "statusline", "claude_md")
} else {
    $Components -split ","
}

Write-Host "Installation scope: ${BLUE}$Scope${RESET}"
Write-Host "Components: ${BLUE}$($componentList -join ', ')${RESET}"
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Proceed with installation? (y/N)"
    if ($confirm -notmatch "^[Yy]") {
        Write-Host "${YELLOW}Installation cancelled.${RESET}"
        exit 0
    }
}

# Backup existing files
$backupItems = @("agents", "skills", "commands", "templates", "CLAUDE.md")
Backup-ExistingFiles -Paths $paths -Items $backupItems

# Ensure base directories exist
if (-not (Test-Path $paths.ClaudeDir)) {
    New-Item -ItemType Directory -Path $paths.ClaudeDir -Force | Out-Null
}

# Session directories for /ag command
$sessionsDir = Join-Path $paths.ClaudeDir "sessions"
$historyDir = Join-Path $paths.ClaudeDir "history"
if (-not (Test-Path $sessionsDir)) {
    New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
}
if (-not (Test-Path $historyDir)) {
    New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
}

$installed = @()

foreach ($component in $componentList) {
    switch ($component.Trim().ToLower()) {
        "agents" {
            Install-Agents -Paths $paths
            $installed += "100+ Specialized Agents"
        }
        "skills" {
            Install-Skills -Paths $paths
            $installed += "Skills (Statusline)"
        }
        "commands" {
            Install-Commands -Paths $paths
            $installed += "Commands (/ag orchestrator)"
        }
        "templates" {
            Install-Templates -Paths $paths
            $installed += "Session Templates"
        }
        "mcp" {
            Install-MCP -Paths $paths
            $installed += "MCP Servers (context7, chrome-devtools, n8n, supabase)"
        }
        "statusline" {
            Install-Statusline -Paths $paths -Mode $StatuslineMode
            $installed += "Statusline ($StatuslineMode mode)"
        }
        "claude_md" {
            Install-ClaudeMd -Paths $paths
            $installed += "CLAUDE.md"
        }
    }
}

Show-Summary -Installed $installed -Scope $Scope

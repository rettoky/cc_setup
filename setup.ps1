<#
.SYNOPSIS
    One-liner installer for Claude Code Pro Plugins
.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/rettoky/cc_setup/main/setup.ps1 | iex

    # With options
    $env:CC_SCOPE="project"; $env:CC_COMPONENTS="agents,skills"; iwr -useb https://raw.githubusercontent.com/rettoky/cc_setup/main/setup.ps1 | iex
#>

$ErrorActionPreference = "Stop"

# Configuration from environment variables
$Scope = if ($env:CC_SCOPE) { $env:CC_SCOPE } else { "project" }
$Components = if ($env:CC_COMPONENTS) { $env:CC_COMPONENTS } else { "agents,skills,templates,claude_md" }
$Mode = if ($env:CC_MODE) { $env:CC_MODE } else { "compact" }

$RepoUrl = "https://github.com/rettoky/cc_setup/archive/refs/heads/main.zip"
$TempDir = Join-Path $env:TEMP "cc_setup_$(Get-Random)"
$ZipFile = "$TempDir.zip"

try {
    Write-Host "Downloading Claude Code Pro Plugins..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $RepoUrl -OutFile $ZipFile -UseBasicParsing

    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force

    $InstallScript = Join-Path $TempDir "cc_setup-main\install.ps1"
    & $InstallScript -Components $Components -Scope $Scope -StatuslineMode $Mode -Force

} finally {
    # Cleanup
    if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force }
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
}

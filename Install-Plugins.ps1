#Requires -Version 5.1
<#
.SYNOPSIS
    Installs all Copilot CLI plugins from this repository.

.DESCRIPTION
    Two modes:

    DEFAULT (from GitHub):
      Detects the GitHub owner/repo from git remote origin, then runs
      'copilot plugin install' for each plugin directory. Requires the
      changes to already be pushed to GitHub.

    LOCAL (from this cloned repo):
      Creates directory junctions inside ~/.copilot/installed-plugins/
      pointing directly at the local plugin directories. Changes are
      reflected immediately — no push required. Ideal for development.

.PARAMETER Plugin
    Optional. Install only the named plugin instead of all plugins.
    Example: .\Install-Plugins.ps1 -Plugin dotnet

.PARAMETER Local
    Install by linking the local cloned directory into the Copilot
    installed-plugins folder. No GitHub push required.

.EXAMPLE
    # Install all plugins from GitHub (after pushing)
    .\Install-Plugins.ps1

    # Install a single plugin from GitHub
    .\Install-Plugins.ps1 -Plugin dotnet

    # Install all plugins from local clone (dev mode)
    .\Install-Plugins.ps1 -Local

    # Install one plugin from local clone
    .\Install-Plugins.ps1 -Plugin dotnet -Local
#>

param(
    [string]$Plugin,
    [switch]$Local
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pluginsRoot = Join-Path $PSScriptRoot 'plugins'

$pluginDirs = if ($Plugin) {
    @(Join-Path $pluginsRoot $Plugin)
} else {
    Get-ChildItem $pluginsRoot -Directory | Select-Object -ExpandProperty FullName
}

# ── LOCAL MODE ────────────────────────────────────────────────────────────────
# Creates a directory junction in ~/.copilot/installed-plugins/_local/<name>
# pointing at the real plugin directory. Edits are live immediately.
if ($Local) {
    $copilotHome = "$env:USERPROFILE\.copilot"
    $installRoot = Join-Path $copilotHome 'installed-plugins\_local'
    if (-not (Test-Path $installRoot)) { New-Item -ItemType Directory -Path $installRoot | Out-Null }

    $linked = 0
    foreach ($dir in $pluginDirs) {
        $name = Split-Path $dir -Leaf
        $pluginJsonPath = Join-Path $dir '.github\plugin\plugin.json'

        if (-not (Test-Path $pluginJsonPath)) {
            Write-Warning "Skipping '$name' — no .github/plugin/plugin.json found."
            continue
        }

        $linkPath = Join-Path $installRoot $name

        if (Test-Path $linkPath) {
            Write-Host "Removing existing link: $linkPath" -ForegroundColor DarkGray
            Remove-Item $linkPath -Force -Recurse
        }

        Write-Host "Linking $name → $dir" -ForegroundColor Cyan
        New-Item -ItemType Junction -Path $linkPath -Target $dir | Out-Null
        $linked++
    }

    Write-Host ""
    Write-Host "$linked plugin(s) linked from local clone." -ForegroundColor Green
    Write-Host "Location: $installRoot" -ForegroundColor DarkGray
    Write-Host "Restart the Copilot CLI to pick up the new plugins." -ForegroundColor Yellow
    return
}

# ── GITHUB MODE ───────────────────────────────────────────────────────────────
# Resolves the GitHub owner/repo from origin remote and runs copilot plugin install.
function Get-GithubRepo {
    $url = git remote get-url origin 2>&1
    if ($LASTEXITCODE -ne 0) { throw "No git remote 'origin' found. Are you inside a cloned git repository?" }

    if ($url -match 'github\.com[:/](.+?)(?:\.git)?$') {
        return $Matches[1]
    }
    throw "Could not parse a GitHub owner/repo from remote URL: $url"
}

$repo = Get-GithubRepo
$installed = 0

foreach ($dir in $pluginDirs) {
    $name = Split-Path $dir -Leaf
    $pluginJsonPath = Join-Path $dir '.github\plugin\plugin.json'

    if (-not (Test-Path $pluginJsonPath)) {
        Write-Warning "Skipping '$name' — no .github/plugin/plugin.json found."
        continue
    }

    $ref = "${repo}:plugins/${name}"
    Write-Host "Installing $ref ..." -ForegroundColor Cyan
    copilot plugin install $ref
    $installed++
}

Write-Host ""
Write-Host "$installed plugin(s) installed from $repo." -ForegroundColor Green

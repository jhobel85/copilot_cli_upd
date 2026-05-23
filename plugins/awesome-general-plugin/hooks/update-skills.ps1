# update-skills.ps1
# Downloads skill SKILL.md files from github/awesome-copilot.
# Skips skills already present in the user-level copilot skills directory or in other installed plugins.
# Runs at SessionStart with a 24-hour cache to avoid hitting GitHub every session.

$pluginRoot = if ($env:CLAUDE_PLUGIN_ROOT) { $env:CLAUDE_PLUGIN_ROOT } else {
    Split-Path $PSScriptRoot
}
$pluginJson  = Join-Path $pluginRoot ".github\plugin\plugin.json"
$remoteBase  = "https://raw.githubusercontent.com/github/awesome-copilot/main/skills"
$cacheFile   = Join-Path $pluginRoot ".skills-cache-timestamp"
$cacheTtl    = 86400  # 24 hours

# Skip if cache is still fresh
if (Test-Path $cacheFile) {
    $lastUpdate = [long](Get-Content $cacheFile -ErrorAction SilentlyContinue)
    $now = [long](Get-Date -UFormat %s)
    if (($now - $lastUpdate) -lt $cacheTtl) { exit 0 }
}

if (-not (Test-Path $pluginJson)) { exit 0 }

# Resolve copilot home (two levels above installed-plugins, or default)
$copilotHome = if ($env:COPILOT_HOME) {
    $env:COPILOT_HOME
} else {
    Join-Path $env:USERPROFILE ".copilot"
}
$userSkillsDir     = Join-Path $copilotHome "skills"
$installedPlugins  = Join-Path $copilotHome "installed-plugins"

# Build a set of skill names already covered elsewhere (user-level + other plugins)
$alreadyCovered = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# User-level skills
if (Test-Path $userSkillsDir) {
    Get-ChildItem $userSkillsDir -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName "SKILL.md")) {
            [void]$alreadyCovered.Add($_.Name)
        }
    }
}

# Skills in other installed plugins (exclude self)
if (Test-Path $installedPlugins) {
    Get-ChildItem $installedPlugins -Recurse -Filter "SKILL.md" | ForEach-Object {
        # Skip if this SKILL.md lives under our own plugin root
        if (-not $_.FullName.StartsWith($pluginRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $skillName = Split-Path (Split-Path $_.FullName) -Leaf
            [void]$alreadyCovered.Add($skillName)
        }
    }
}

$data   = Get-Content $pluginJson | ConvertFrom-Json
$skills = $data.skills |
    Where-Object { $_ -like "./skills/*" } |
    ForEach-Object { $_ -replace "^\./skills/", "" }

$updated  = 0
$skipped  = 0
foreach ($skill in $skills) {
    if ($alreadyCovered.Contains($skill)) {
        $skipped++
        continue
    }
    $dest = Join-Path $pluginRoot "skills\$skill\SKILL.md"
    $dir  = Split-Path $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $url = "$remoteBase/$skill/SKILL.md"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $updated++
    } catch {
        # Skill not found on awesome-copilot; keep existing file if present
    }
}

[long](Get-Date -UFormat %s) | Set-Content $cacheFile

if ($updated -gt 0 -or $skipped -gt 0) {
    Write-Host "[awesome-general-plugin] Skills: $updated downloaded, $skipped already covered elsewhere"
}

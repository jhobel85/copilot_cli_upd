---
name: create-copilot-plugin
description: Use when creating a custom Copilot CLI plugin to group selected skills under one name that can be easily enabled or disabled, optionally sourcing skills from marketplaces like awesome-copilot or superpowers.
---

# Create Custom Copilot CLI Plugin

## Overview

Bundle selected skills into a named plugin hosted in a GitHub repo, then install it via `copilot plugin install`. This allows enabling/disabling a group of skills as one unit.

## Plugin Structure (required)

```
plugins/<plugin-name>/
  .github/
    plugin/
      plugin.json       ← REQUIRED for copilot plugin install
  skills/
    <skill-name>/
      SKILL.md
```

The `plugin.json` file is **mandatory** — without it `copilot plugin install` will fail with "No plugin.json found".

## Workflow

> **⛔ Git Rule:** This skill creates files that must be pushed to GitHub before installation.
> **NEVER auto-commit.** Always stage → show diff → ask the user for explicit approval → then commit.

### 1. Collect requirements

Ask the user:
- **Plugin name** (letters, numbers, hyphens only, e.g. `dotnet`)
- **Target GitHub repo** for hosting (e.g. `jhobel85/PersonalLife`)
- **Path prefix** in repo (e.g. `plugins`)
- **Skills to include** — name + source for each

### 2. Locate source SKILL.md files

| Source | Fetch path |
|--------|-----------|
| awesome-copilot | `github/awesome-copilot:plugins/<plugin>/skills/<skill>/SKILL.md` |
| superpowers | `obra/superpowers-marketplace:skills/<skill>/SKILL.md` |
| custom repo | `owner/repo:path/to/skill/SKILL.md` |
| local user skills | `~/.copilot/skills/<skill>/SKILL.md` |

Use GitHub API or `gh api` to fetch raw content:
```powershell
gh api repos/github/awesome-copilot/contents/plugins/csharp-dotnet-development/skills/dotnet-best-practices/SKILL.md --jq '.content' | [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($input -join '')))
```

Or fetch raw URL directly:
```
https://raw.githubusercontent.com/<owner>/<repo>/main/<path>/SKILL.md
```

### 3. Create plugin.json (REQUIRED)

Create `.github/plugin/plugin.json` inside the plugin directory. Without this file `copilot plugin install` will fail with "No plugin.json found":

```powershell
New-Item -ItemType Directory -Force "C:\git\<repo>\plugins\<plugin-name>\.github\plugin" | Out-Null
```

Content of `plugin.json`:
```json
{
  "name": "<plugin-name>",
  "description": "<Short description of plugin purpose>",
  "version": "1.0.0",
  "author": { "name": "<your-github-username>" },
  "repository": "https://github.com/<owner>/<repo>",
  "license": "MIT",
  "keywords": ["<tag1>", "<tag2>"],
  "skills": [
    "./skills/<skill-name-1>",
    "./skills/<skill-name-2>"
  ]
}
```

### 4. Create plugin skill directories and SKILL.md files

```powershell
$base = "C:\git\<repo>\plugins\<plugin-name>"
New-Item -ItemType Directory -Force "$base\skills\<skill-name>"
# Write SKILL.md content to each skill directory
```

### 5. Stage, review and commit (USER APPROVAL REQUIRED)

**⛔ NEVER run `git commit` automatically. Always ask the user first.**

Stage the files and show a diff, then stop and ask:

```powershell
git add plugins/<plugin-name>/
git status
git --no-pager diff --cached --stat
```

After showing the diff, **stop and ask the user**:

> "The files above are staged. Should I commit and push them?
> If yes, please confirm — I'll use this message:
> `Add <plugin-name> plugin with skills: <list>`
> Or provide your own message."

Only proceed with the commit and push **after receiving explicit user confirmation**:

```powershell
# Run ONLY after user says yes / confirms commit message
git commit -m "<user-approved message>"
git push
```

### 6. Install plugin via CLI and verify (REQUIRED)

After pushing, install using the CLI command and **always verify** it appears in `copilot plugin list`. If verification fails, report an error and stop:

```powershell
$owner = "<owner>"
$repo = "<repo>"
$pluginName = "<plugin-name>"

# Install
copilot plugin install "$owner/$repo`:plugins/$pluginName"

# Verify — MUST show the plugin, otherwise fail
$installed = copilot plugin list 2>&1
if ($installed -match $pluginName) {
    Write-Host "✅ Plugin '$pluginName' installed successfully and visible in 'copilot plugin list'."
} else {
    Write-Error "❌ Plugin install failed — '$pluginName' not found in 'copilot plugin list'. Check: plugin.json exists at .github/plugin/plugin.json, repo is pushed and accessible."
    exit 1
}
```

### 7. Keeping the install in sync

After updating skills, stage changes and show a diff, then **ask the user before committing**:

```powershell
git add plugins/<plugin-name>/
git --no-pager diff --cached --stat
```

> "The updated skill files are staged (see diff above). Should I commit and push?
> Proposed message: `Update <plugin-name> plugin skills`"

Only after explicit user confirmation:

```powershell
# Run ONLY after user confirms
git commit -m "<user-approved message>"
git push
copilot plugin install <owner>/<repo>:plugins/<plugin-name>
```

## Enable / Disable

| Action | Command |
|--------|---------|
| Install | `copilot plugin install owner/repo:plugins/<name>` |
| List installed | `copilot plugin list` |
| Disable | `copilot plugin disable <name>` |
| Enable | `copilot plugin enable <name>` |
| Update | Push changes then re-run `copilot plugin install owner/repo:plugins/<name>` |

## Soft Deactivation / Reactivation (recommended over uninstall)

Use this workflow to **temporarily disable** a plugin without losing its full install specifier. This lets you reactivate by name alone — no need to remember `plugin@marketplace`.

The registry lives at `$HOME\.copilot\plugins-registry.json` and is maintained by the AI agent using the inline commands below. No external scripts required.

### Register a plugin (before first deactivation)

If a plugin has never been registered, read its full specifier from `copilot plugin list` output and save it. Run this once per plugin:

```powershell
$registryPath = "$HOME\.copilot\plugins-registry.json"
$registry = if (Test-Path $registryPath) { Get-Content $registryPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{ plugins = @() } }

$pluginName    = "<name>"       # e.g. "dotnet"
$fullSpecifier = "<specifier>"  # e.g. "dotnet@awesome-copilot"  — from: copilot plugin list

$existing = $registry.plugins | Where-Object { $_.name -eq $pluginName }
if ($null -eq $existing) {
    $registry.plugins = @($registry.plugins) + [pscustomobject]@{ name = $pluginName; specifier = $fullSpecifier; status = "active" }
    $registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
    Write-Host "Registered: $pluginName → $fullSpecifier"
} else {
    Write-Host "Already registered: $pluginName"
}
```

### Deactivate (soft uninstall)

Physically uninstalls the plugin from Copilot CLI, but keeps its specifier in the registry:

```powershell
$registryPath = "$HOME\.copilot\plugins-registry.json"
$registry  = Get-Content $registryPath -Raw | ConvertFrom-Json
$pluginName = "<name>"   # e.g. "dotnet"

$entry = $registry.plugins | Where-Object { $_.name -eq $pluginName }
if ($null -eq $entry) { throw "Plugin '$pluginName' not in registry. Register it first." }
if ($entry.status -eq "inactive") { Write-Host "Already inactive."; return }

copilot plugin uninstall $pluginName
$entry.status = "inactive"
$registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
Write-Host "Plugin '$pluginName' deactivated. Registry status: inactive."
```

### Reactivate (soft install)

Reinstalls from the stored specifier — just the short name needed:

```powershell
$registryPath = "$HOME\.copilot\plugins-registry.json"
$registry   = Get-Content $registryPath -Raw | ConvertFrom-Json
$pluginName  = "<name>"   # e.g. "dotnet"

$entry = $registry.plugins | Where-Object { $_.name -eq $pluginName }
if ($null -eq $entry) { throw "Plugin '$pluginName' not in registry. Register it first." }
if ($entry.status -eq "active") { Write-Host "Already active."; return }

copilot plugin install $entry.specifier
$entry.status = "active"
$registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
Write-Host "Plugin '$pluginName' activated via: $($entry.specifier)"
```

### View registry

```powershell
Get-Content "$HOME\.copilot\plugins-registry.json" | ConvertFrom-Json | Select-Object -ExpandProperty plugins | Format-Table name, status, specifier
```

### Why not `copilot plugin uninstall`?

`copilot plugin uninstall <name>` **permanently removes** the plugin. You would need the full specifier (e.g., `dotnet@awesome-copilot`) to reinstall it. This workflow avoids that by preserving the specifier in the registry.

## Common Mistakes

- **Missing `plugin.json`** — `copilot plugin install` fails with "No plugin.json found". Must be at `.github/plugin/plugin.json`
- **Not pushed before installing** — CLI fetches from GitHub; local-only changes are invisible
- **Manually copying files or editing `config.json`** — Does NOT persist across restarts; only `copilot plugin install` creates a durable install
- **Not verifying after install** — Always run `copilot plugin list` and confirm the plugin appears; report failure if it does not
- **Repo is private without auth** — Plugin install may fail if the repo is not accessible

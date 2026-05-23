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
- **Target GitHub repo** for hosting (e.g. `<owner>/<repo>` — auto-detected from `git remote origin`)
- **Path prefix** in repo (e.g. `plugins`)
- **Skills to include** — name + source for each

### 1a. Gap analysis — only include missing skills

Before selecting skills, audit what is **already available** in the user's Copilot space so the new plugin only adds what is genuinely missing.

**Step 1 — Collect all currently covered skill names:**

```powershell
$copilotHome = Join-Path $env:USERPROFILE ".copilot"
$covered = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# User-level skills (~/.copilot/skills/)
Get-ChildItem (Join-Path $copilotHome "skills") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName "SKILL.md")) { [void]$covered.Add($_.Name) }
}

# Skills in all installed plugins (~/.copilot/installed-plugins/**/skills/)
Get-ChildItem (Join-Path $copilotHome "installed-plugins") -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
    [void]$covered.Add((Split-Path (Split-Path $_.FullName) -Leaf))
}

Write-Host "=== Already covered ($($covered.Count) skills) ==="
$covered | Sort-Object | ForEach-Object { Write-Host "  ✓ $_" }
```

**Step 2 — Identify skills needed by the project:**

Inspect the project's tech stack (languages, frameworks, tooling) to determine which skill categories are relevant. Sources to check:
- File extensions / project files (`.csproj`, `package.json`, `go.mod`, `Dockerfile`, etc.)
- `README.md` / `CONTRIBUTING.md` for stated tooling
- Awesome-copilot for matching skill names: `https://github.com/github/awesome-copilot/tree/main/skills`

**Step 3 — Compute the gap (candidate skills minus covered):**

```powershell
# Skills you identified as relevant for this project:
$candidates = @(
    "dotnet-best-practices",
    "security-best-practices",
    "test-driven-development"
    # ... add others relevant to the project
)

$gaps = $candidates | Where-Object { -not $covered.Contains($_) }

Write-Host "`n=== Skills to include in new plugin (gaps only) ==="
$gaps | ForEach-Object { Write-Host "  + $_" }

Write-Host "`n=== Skipped (already covered) ==="
($candidates | Where-Object { $covered.Contains($_) }) | ForEach-Object { Write-Host "  ✓ $_ (already present)" }
```

**Present the gap list to the user for confirmation before proceeding.**  
Only include the confirmed gap skills in `plugin.json`.

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

---

## Full Project Copilot Environment Setup

Beyond plugins, a well-configured project repo typically includes four additional components. Set them up in this order when bootstrapping a new project.

### Recommended repo layout

```
<repo-root>/
  Instructions/
    src/
      layer.meta.md        ← edit these source layers
      layer.dev.md
      layer.agentic.md
    build-instructions.ps1 ← assembles the outputs below
    copilot-instructions.meta.md     ← generated, DO NOT edit
    copilot-instructions.dev.md      ← generated, DO NOT edit
    copilot-instructions.agentic.md  ← generated, DO NOT edit
  MCP/
    mcp-config.json        ← MCP server definitions
  Scripts/
    *.ps1 / *.sh           ← utility scripts
  git-hooks/
    git-autocommit-block   ← AI commit guard (sh)
    pre-commit             ← delegates to guard (sh)
    Install-GitHooks.ps1   ← installer script
  plugins/
    <plugin-name>/
      .github/plugin/plugin.json
      hooks/
        hooks.json
        ...
```

---

### 1. Copilot Instructions (layered system)

Instructions tell the AI agent how to behave. The repo uses **three additive layers** so different contexts load only what they need.

| Output file | Layers included | Use when |
|---|---|---|
| `copilot-instructions.meta.md` | meta only | minimal context (git rules, ask vs decide) |
| `copilot-instructions.dev.md` | meta + dev | standard coding sessions (TDD, rubber duck, code quality) |
| `copilot-instructions.agentic.md` | meta + dev + agentic | fleet agents, orchestrator, memory graph |

**Source layers** live in `Instructions/src/`. Always edit the source files, never the generated outputs.

**Regenerate outputs** after any source edit:

```powershell
.\Instructions\build-instructions.ps1
```

**Activate for a project** — symlink or copy the right output to `.github/copilot-instructions.md`:

```powershell
# For a standard dev session:
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md

# Or point the CLI at a specific file via /instructions command inside copilot
```

**Layer content guide:**
- `layer.meta.md` — Git rules, ask-vs-decide, memory access policy
- `layer.dev.md` — TDD mandate, rubber duck triggers, superpowers skill table, code quality rules
- `layer.agentic.md` — Memory graph write rules, fleet coordination, convergence criteria, stall prevention

---

### 2. Git Hooks — AI Commit Guard

Blocks all `git commit` calls unless a human explicitly sets `GIT_HUMAN_APPROVED=1`. Prevents AI agents and autopilot from committing without approval.

**Files:**

| File | Purpose |
|---|---|
| `git-hooks/git-autocommit-block` | Core guard logic (POSIX sh) |
| `git-hooks/pre-commit` | Git entry point — delegates to guard |
| `git-hooks/Install-GitHooks.ps1` | Installer (local repo or global) |

**Install locally** (this repo only):

```powershell
.\git-hooks\Install-GitHooks.ps1
```

**Install globally** (all repos on this machine):

```powershell
.\git-hooks\Install-GitHooks.ps1 -Global
```

**Uninstall:**

```powershell
.\git-hooks\Install-GitHooks.ps1 -Uninstall          # local
.\git-hooks\Install-GitHooks.ps1 -Global -Uninstall  # global
```

**To commit as a human after installation:**

```powershell
# PowerShell
$env:GIT_HUMAN_APPROVED = 1; git commit -m "your message"
```

```bash
# Git Bash / WSL
GIT_HUMAN_APPROVED=1 git commit -m "your message"
```

VS Code Source Control commits are always allowed automatically (detected via `VSCODE_GIT_IPC_HANDLE`).

**Bypass (use sparingly):**

```bash
git commit --no-verify -m "your message"
```

---

### 3. Scripts

Utility scripts live in `Scripts/`. They are standalone — no install step required, just run directly.

| Script | Purpose |
|---|---|
| `convert-onenote-to-markdown.ps1` | Converts OneNote exports to Markdown (PowerShell) |
| `convert-onenote-to-markdown.sh` | Same conversion for Unix/WSL |
| `transformFilesToMd.sh` | Batch-transforms files to Markdown format |

**Run a script:**

```powershell
.\Scripts\convert-onenote-to-markdown.ps1
```

When adding new scripts: place them in `Scripts/`, use descriptive kebab-case names, and document purpose in a comment at the top.

---

### 4. MCP Servers

MCP (Model Context Protocol) servers extend the AI agent with additional tools. Configuration lives in `MCP/mcp-config.json`.

**Current configuration:**

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

The `memory` server provides a persistent **knowledge graph** for cross-session context. The orchestrator agent reads and writes it; sub-agents and fleet workers read only.

**Activate MCP config in the CLI:**

```
/mcp add --config MCP/mcp-config.json
```

Or merge entries into `~/.copilot/mcp.json` for user-level availability across all projects.

**Adding a new MCP server:**

```json
{
  "mcpServers": {
    "memory": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-memory"] },
    "my-server": { "command": "node", "args": ["path/to/server.js"] }
  }
}
```

Then run `/mcp` inside the Copilot CLI to verify the server appears and connects.

---
name: create-copilot-plugin
description: Use when bootstrapping or extending a Copilot CLI project 
  environment — creates plugins with custom skills, generates tailored AGENTS.md
  and instruction files, configures MCP servers based on tech stack, installs 
  git hooks, and validates everything is consistent with no duplicates.
---

# Bootstrap Copilot Environment for a Project

## Overview

This skill sets up or extends the complete Copilot CLI environment for a project repo. It covers six components that must work together without duplication:

1. **Copilot Instructions** — choose and customise the instruction file
2. **AGENTS.md** — generate a tailored agent rules file
3. **MCP Servers** — detect tech stack and configure relevant servers
4. **Git Hooks** — install the AI commit guard
5. **Plugins & Skills** — gap-analyse and create a custom plugin
6. **Consistency Check** — validate all components are aligned

Run them in order when bootstrapping a new project. For an existing project, run only the steps that are missing.

> **⛔ Git Rule:** This skill creates files that must be pushed to GitHub before plugin installation.  
> **NEVER auto-commit.** Always stage → show diff → ask the user for explicit approval → then commit.

---

## Recommended repo layout

```
<repo-root>/
  .github/
    copilot-instructions.md    ← active instruction file (copied from Instructions/)
  Instructions/
    copilot-instructions.meta.md   ← edit directly (git rules, ask-vs-decide, skills ref)
    copilot-instructions.dev.md    ← edit directly (meta + TDD, rubber duck, code quality)
    README.md
  AGENTS.md                        ← agentic rules (agent roles, fleet, memory protocol)
  MCP/
    mcp-config.json            ← MCP server definitions
  git-hooks/
    git-autocommit-block       ← AI commit guard (POSIX sh)
    pre-commit                 ← delegates to guard
    Install-GitHooks.ps1       ← installer
  plugins/
    <plugin-name>/
      .github/plugin/plugin.json
      skills/
        <skill-name>/
          SKILL.md
```

---

## Step 1 — Copilot Instructions

Instructions tell the AI agent how to behave. Choose the right file for the project's needs.

| File | Content | Use when |
|---|---|---|
| `copilot-instructions.meta.md` | Git rules, ask-vs-decide, skills reference | lightweight / non-dev sessions |
| `copilot-instructions.dev.md` | meta + TDD, rubber duck, code quality rules | standard development sessions |

### 1a. Determine which file to use

Ask the user if unclear: "Is this a standard development project (use `dev.md`) or does it only need minimal agent guidance (use `meta.md`)?"

### 1b. Customise the skills table

Before copying, clean the skills table to only list skills that are actually installed:

```powershell
copilot skill list
```

Remove any row from the `## Skills` table whose skill name is not in the output. This prevents agents from trying to invoke skills that don't exist.

### 1c. Activate

```powershell
# Copy chosen file to the project's active instruction location:
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md

# Create .github/ if it doesn't exist:
New-Item -ItemType Directory -Force .github | Out-Null
```

Verify it is picked up: open a new Copilot session and confirm the instructions appear.

---

## Step 2 — AGENTS.md

`AGENTS.md` defines agent roles, fleet coordination rules, and memory protocol for agentic / multi-agent sessions. It lives in the repo root so all AI agents (Copilot CLI, Codex, Claude Code, etc.) pick it up automatically.

> **Extend, don't duplicate.** The base `Instructions/AGENTS.md` already defines the full protocol (Reasoning Protocol, Gap Analysis, Agent Roles, Memory Graph, Fleet Coordination, Stall Prevention, Iterative Convergence). The project `AGENTS.md` copies that base and then adds **only** what is project-specific. Never rewrite a section that already exists in the base.

### 2a. Start from base

```powershell
# Copy the base AGENTS.md to the repo root — this is the starting point:
Copy-Item Instructions\AGENTS.md AGENTS.md
```

### 2b. Update the Skills table

The base Skills table lists generic orchestration skills. Replace it with the skills actually installed in this project:

```powershell
copilot skill list
```

In `AGENTS.md`, update the `## Skills` section: keep only rows whose skill name appears in the output above. Add rows for any project-specific skills not already listed.

**Rule:** Never list a skill that is not installed — it causes agent confusion.

### 2c. Add project-specific extensions

Append project-specific sections **below** the base content. Only add what is genuinely project-specific and not already covered by the base:

```markdown
## Project Constraints
<!-- Optional: project-specific rules that override or extend the base -->
- <constraint>

## Domain Roles
<!-- Optional: add only if the project has domain-specific agent roles beyond the base set -->
| Role | Responsibility |
|---|---|
| `<RoleName>` | <what it does> |
```

Leave out any section already present in the base. If no project-specific additions are needed, the copied base file is sufficient as-is.

---

## Step 3 — MCP Servers

MCP servers extend the AI agent with additional tools (filesystem access, GitHub API, databases, memory, etc.). Detect the project's tech stack and configure only what's relevant.

### 3a. Detect tech stack

```powershell
# Inspect project root for tech stack signals:
$signals = @{
    CSharp    = (Get-ChildItem -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    Node      = Test-Path "package.json"
    Docker    = Test-Path "docker-compose.yml"
    Sql       = (Get-ChildItem -Recurse -Include "*.sql","db" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    GitHub    = Test-Path ".github"
    AnyProject = $true  # memory is always useful
}
$signals
```

### 3b. MCP server recommendations

| Tech signal | Recommended MCP server | npm package |
|---|---|---|
| Any project | `memory` — cross-session knowledge graph | `@modelcontextprotocol/server-memory` |
| `.github/` present | `github` — PR/issue/repo API | `@modelcontextprotocol/server-github` |
| `package.json` / `.csproj` | `filesystem` — file read/write tools | `@modelcontextprotocol/server-filesystem` |
| `docker-compose.yml` | `filesystem` + consider `docker` | — |
| `*.sql` / `db/` folder | `sqlite` or `postgres` | `@modelcontextprotocol/server-sqlite` |

Present the recommendations to the user and ask which to include before generating config.

### 3c. Generate mcp-config.json

```powershell
New-Item -ItemType Directory -Force MCP | Out-Null
```

Example config (include only selected servers):

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "<token>" }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "<repo-root>"]
    }
  }
}
```

### 3d. Check for duplicates before activating

```powershell
# Check if any server names already exist in user-level MCP config:
$userMcp = "$HOME\.copilot\mcp.json"
if (Test-Path $userMcp) {
    $existing = (Get-Content $userMcp | ConvertFrom-Json).mcpServers.PSObject.Properties.Name
    Write-Host "Already in user MCP config: $($existing -join ', ')"
    Write-Host "Do not add these to project config — they are already available globally."
}
```

### 3e. Activate

```
/mcp add --config MCP/mcp-config.json
```

Verify: run `/mcp` inside Copilot CLI and confirm all servers appear and connect.

---

## Step 4 — Git Hooks (AI Commit Guard)

Blocks all `git commit` calls unless a human explicitly sets `GIT_HUMAN_APPROVED=1`. Prevents AI agents from committing without approval.

### 4a. Install

```powershell
# Local (this repo only):
.\git-hooks\Install-GitHooks.ps1

# Global (all repos on this machine):
.\git-hooks\Install-GitHooks.ps1 -Global
```

### 4b. Verify

```powershell
# Should be blocked:
git commit -m "test" --allow-empty
# Expected: "AI auto-commit blocked..."

# Should work (human approval):
$env:GIT_HUMAN_APPROVED = 1; git commit -m "test" --allow-empty
```

### 4c. Commit as human

```powershell
# PowerShell:
$env:GIT_HUMAN_APPROVED = 1; git commit -m "your message"
```

```bash
# Git Bash / WSL:
GIT_HUMAN_APPROVED=1 git commit -m "your message"
```

VS Code Source Control commits are always allowed automatically.

---

## Step 5 — Plugins & Custom Skills

Create a custom plugin to bundle skills that are missing from the project's Copilot space.

### 5a. Gap analysis — only include missing skills

**Step 1 — Collect all currently covered skill names:**

```powershell
$copilotHome = Join-Path $env:USERPROFILE ".copilot"
$covered = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

Get-ChildItem (Join-Path $copilotHome "skills") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName "SKILL.md")) { [void]$covered.Add($_.Name) }
}
Get-ChildItem (Join-Path $copilotHome "installed-plugins") -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
    [void]$covered.Add((Split-Path (Split-Path $_.FullName) -Leaf))
}

Write-Host "=== Already covered ($($covered.Count) skills) ==="
$covered | Sort-Object | ForEach-Object { Write-Host "  ✓ $_" }
```

**Step 2 — Compute gaps:**

```powershell
$candidates = @(
    # Add skills relevant to this project's tech stack:
    "dotnet-best-practices",
    "security-best-practices"
)

$gaps = $candidates | Where-Object { -not $covered.Contains($_) }
Write-Host "`n=== Gaps (include in new plugin) ===" ; $gaps | ForEach-Object { Write-Host "  + $_" }
Write-Host "`n=== Already covered (skip) ===" ; ($candidates | Where-Object { $covered.Contains($_) }) | ForEach-Object { Write-Host "  ✓ $_" }
```

**Present the gap list to the user for confirmation before proceeding.** Only include confirmed gaps in `plugin.json`.

### 5b. Collect requirements

Ask the user:
- **Plugin name** (letters, numbers, hyphens only, e.g. `dotnet`)
- **Target GitHub repo** (auto-detected from `git remote origin`)
- **Path prefix** in repo (default: `plugins`)

### 5c. Locate source SKILL.md files

| Source | Fetch path |
|--------|-----------|
| awesome-copilot | `github/awesome-copilot:plugins/<plugin>/skills/<skill>/SKILL.md` |
| superpowers | `obra/superpowers-marketplace:skills/<skill>/SKILL.md` |
| custom repo | `owner/repo:path/to/skill/SKILL.md` |
| local user skills | `~/.copilot/skills/<skill>/SKILL.md` |

```powershell
gh api repos/github/awesome-copilot/contents/plugins/<plugin>/skills/<skill>/SKILL.md --jq '.content' | `
  [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($input -join '')))
```

### 5d. Create plugin.json (REQUIRED)

```powershell
New-Item -ItemType Directory -Force "plugins\<plugin-name>\.github\plugin" | Out-Null
```

```json
{
  "name": "<plugin-name>",
  "description": "<Short description>",
  "version": "1.0.0",
  "author": { "name": "<github-username>" },
  "repository": "https://github.com/<owner>/<repo>",
  "license": "MIT",
  "keywords": ["<tag>"],
  "skills": [
    "./skills/<skill-name>"
  ]
}
```

### 5e. Create SKILL.md files

Each skill directory needs a `SKILL.md` with YAML frontmatter:

```markdown
---
name: <skill-name>
description: '<When to use this skill — one sentence>'
---

# <Skill Title>

...skill content...
```

### 5f. Stage, review, commit (USER APPROVAL REQUIRED)

```powershell
git add plugins/<plugin-name>/
git status
git --no-pager diff --cached --stat
```

Stop and ask the user for commit approval. Only proceed after explicit confirmation:

```powershell
# ONLY after user confirms:
git commit -m "Add <plugin-name> plugin with skills: <list>"
git push
```

### 5g. Install plugin and verify

```powershell
$ref = "<owner>/<repo>:plugins/<plugin-name>"
copilot plugin install $ref

$installed = copilot plugin list 2>&1
if ($installed -match "<plugin-name>") {
    Write-Host "✅ Plugin installed and visible in 'copilot plugin list'."
} else {
    Write-Error "❌ Plugin not found after install. Check: plugin.json exists, repo is pushed and accessible."
    exit 1
}
```

---

## Step 6 — Consistency Check

After all components are set up, validate that nothing is duplicated and everything references what actually exists.

### Checklist

**Skills consistency:**
```powershell
$installedSkills = copilot skill list 2>&1
# For each skill listed in .github/copilot-instructions.md skills table:
#   → verify it appears in $installedSkills
# For each skill listed in AGENTS.md skills table:
#   → verify it appears in $installedSkills
# Report any orphaned references
```

**Plugin coverage — no duplicates:**
```powershell
# List all installed skills grouped by source plugin:
copilot skill list
# Verify no skill name appears in more than one plugin
```

**MCP — no double-configuration:**
```powershell
$userMcp     = if (Test-Path "$HOME\.copilot\mcp.json") { (Get-Content "$HOME\.copilot\mcp.json" | ConvertFrom-Json).mcpServers.PSObject.Properties.Name } else { @() }
$projectMcp  = (Get-Content "MCP\mcp-config.json" | ConvertFrom-Json).mcpServers.PSObject.Properties.Name
$overlap = $userMcp | Where-Object { $projectMcp -contains $_ }
if ($overlap) { Write-Warning "Duplicate MCP servers (remove from project config): $($overlap -join ', ')" }
else { Write-Host "✅ No MCP duplicates." }
```

**AGENTS.md skills ↔ instruction file skills — must match:**
- Open `AGENTS.md` and `.github/copilot-instructions.md`
- Skill tables should be identical or the instruction file's table should be a superset
- Remove any skill from AGENTS.md that is not in the instruction file's table

**Summary gate:** Only declare the bootstrap complete when all checks pass with zero warnings.

---

## Enable / Disable Plugins

| Action | Command |
|--------|---------|
| Install | `copilot plugin install owner/repo:plugins/<name>` |
| List installed | `copilot plugin list` |
| Disable | `copilot plugin disable <name>` |
| Enable | `copilot plugin enable <name>` |
| Update | Push changes → re-run `copilot plugin install owner/repo:plugins/<name>` |

## Soft Deactivation / Reactivation (recommended over uninstall)

Use this workflow to temporarily disable a plugin without losing its full install specifier.

The registry lives at `$HOME\.copilot\plugins-registry.json` and is maintained by the AI agent. No external scripts required.

### Register a plugin (before first deactivation)

```powershell
$registryPath = "$HOME\.copilot\plugins-registry.json"
$registry = if (Test-Path $registryPath) { Get-Content $registryPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{ plugins = @() } }

$pluginName    = "<name>"
$fullSpecifier = "<specifier>"  # from: copilot plugin list

$existing = $registry.plugins | Where-Object { $_.name -eq $pluginName }
if ($null -eq $existing) {
    $registry.plugins = @($registry.plugins) + [pscustomobject]@{ name = $pluginName; specifier = $fullSpecifier; status = "active" }
    $registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
    Write-Host "Registered: $pluginName → $fullSpecifier"
} else { Write-Host "Already registered: $pluginName" }
```

### Deactivate (soft uninstall)

```powershell
$registryPath = "$HOME\.copilot\plugins-registry.json"
$registry  = Get-Content $registryPath -Raw | ConvertFrom-Json
$pluginName = "<name>"

$entry = $registry.plugins | Where-Object { $_.name -eq $pluginName }
if ($null -eq $entry) { throw "Plugin '$pluginName' not in registry. Register it first." }
if ($entry.status -eq "inactive") { Write-Host "Already inactive."; return }

copilot plugin uninstall $pluginName
$entry.status = "inactive"
$registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
Write-Host "Plugin '$pluginName' deactivated."
```

### Reactivate (soft install)

```powershell
$registryPath = "$HOME\.copilot\plugins-registry.json"
$registry   = Get-Content $registryPath -Raw | ConvertFrom-Json
$pluginName  = "<name>"

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

## Common Mistakes

- **Missing `plugin.json`** — `copilot plugin install` fails with "No plugin.json found". Must be at `.github/plugin/plugin.json`
- **Not pushed before installing** — CLI fetches from GitHub; local-only changes are invisible
- **Manually copying files or editing `config.json`** — Does NOT persist across restarts; only `copilot plugin install` creates a durable install
- **Not verifying after install** — Always run `copilot plugin list` and confirm the plugin appears
- **Listing non-installed skills in instructions/AGENTS.md** — Causes agent confusion; always run `copilot skill list` first
- **Duplicate MCP servers** — Check user-level `~/.copilot/mcp.json` before adding servers to project config
- **SKILL.md missing frontmatter** — Skill won't be registered by the CLI; must have `---\nname: ...\ndescription: ...\n---` at line 1


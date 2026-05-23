# Plugins

Copilot CLI plugins bundle skills under a single installable name.

## Install

```powershell
# Local clone — generates copilot-dev.ps1 wrapper (no push required)
.\Install-Plugins.ps1 -Local [-Plugin <name>]
# then: .\copilot-dev.ps1 instead of copilot

# From GitHub — auto-detects repo from git remote origin
.\Install-Plugins.ps1 [-Plugin <name>]
```

Bash: same flags with `./install-plugins.sh [--local] [<name>]` → generates `copilot-dev.sh`

## Available Plugins

| Plugin | Skills | Description |
|--------|--------|-------------|
| [awesome-general-plugin](awesome-general-plugin/README.md) | Downloaded live from `github/awesome-copilot` | General-purpose skills |
| [custom-general-plugin](custom-general-plugin/README.md) | `orchestrator-manager`, `create-copilot-plugin`, `superpowers-safety` | Workflow management |
| [dotnet](dotnet/README.md) | `dotnet-best-practices`, `dotnet-design-pattern-review` | .NET/C# code quality |

## Plugin Management

| Action | Command |
|--------|---------|
| List | `copilot plugin list` |
| Disable | `copilot plugin disable <name>` |
| Enable | `copilot plugin enable <name>` |
| Update | Re-run install script after changes |

## Plugin Structure

```
plugins/<name>/
  .github/plugin/plugin.json   ← REQUIRED
  skills/<skill-name>/SKILL.md
  hooks/                       ← optional SessionStart hooks
```

### Required fields in `plugin.json`

`name`, `description`, `author`, and `repository` are **mandatory** — `copilot plugin install` fails without them.

## Adding a New Plugin

Use the `create-copilot-plugin` skill for guided creation, or manually:

1. Create `plugins/<name>/.github/plugin/plugin.json`
2. Add `skills/<skill-name>/SKILL.md` files
3. Run `.\Install-Plugins.ps1 -Local -Plugin <name>` → then use `.\copilot-dev.ps1`
4. Verify: `copilot plugin list`

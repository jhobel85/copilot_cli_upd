# awesome-general-plugin

General-purpose skills downloaded live from [`github/awesome-copilot`](https://github.com/github/awesome-copilot) — nothing stored locally.

## Install

```powershell
.\Install-Plugins.ps1 -Local -Plugin awesome-general-plugin   # local clone
.\Install-Plugins.ps1 -Plugin awesome-general-plugin          # from GitHub
```

## Skills

Only downloads skills **not already present** in `~/.copilot/skills/` or other installed plugins.

| Skill | Description |
|-------|-------------|
| `acquire-codebase-knowledge` | Map, document, and onboard into an existing codebase |
| `add-educational-comments` | Add educational comments to specified files |
| `cli-mastery` | General-purpose CLI guidance and shell workflows |
| `copilot-usage-metrics` | Retrieve GitHub Copilot usage metrics via CLI and REST API |
| `mentoring-juniors` | Code-review checklists and mentoring prompts for junior devs |
| `microsoft-docs` | Fetch official Microsoft documentation |
| `security-best-practices` | Review secrets, auth, encryption, and secure defaults |
| `ai-prompt-engineering-safety-review` | Safety review and improvement for AI prompts |
| `breakdown-feature-implementation` | Create detailed feature implementation plans |
| `create-github-issues-feature-from-implementation-plan` | Create GitHub Issues from implementation plan phases |
| `create-implementation-plan` | Write implementation plan files for features or refactors |
| `drawio` | Generate draw.io diagrams exported to PNG/SVG/PDF |
| `update-implementation-plan` | Update existing implementation plan files |

## Download Behaviour

`SessionStart` hook runs every session; skips if cache is less than 24 hours old. Downloads only the gap skills from `https://raw.githubusercontent.com/github/awesome-copilot/main/skills/<name>/SKILL.md`. Files are written to the installed plugin directory, never committed to this repo.

To force a refresh, delete the cache file (find the path with `copilot plugin list`):

```powershell
Remove-Item "$env:USERPROFILE\.copilot\installed-plugins\<your-plugin-dir>\.skills-cache-timestamp"
```


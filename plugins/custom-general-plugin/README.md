# custom-general-plugin

Custom workflow management skills: orchestration, plugin creation, and commit safety checks.

## Install

```powershell
.\Install-Plugins.ps1 -Local -Plugin custom-general-plugin   # local → use .\copilot-dev.ps1
.\Install-Plugins.ps1 -Plugin custom-general-plugin          # from GitHub
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `orchestrator-manager` | Managing complex multi-step tasks | Decomposes tasks into subagents, enforces safety, gates human approvals |
| `create-copilot-plugin` | Creating a new Copilot CLI plugin | Gap analysis → plugin.json → skills → install → verify |

Skills are committed directly to this repo.


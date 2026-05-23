# git-hooks — AI Commit Guard

Blocks `git commit` from AI agents and scripts unless `GIT_HUMAN_APPROVED=1` is set. VS Code Source Control commits pass automatically.

## Install

```powershell
.\git-hooks\Install-GitHooks.ps1           # this repo only
.\git-hooks\Install-GitHooks.ps1 -Global   # all repos on this machine
.\git-hooks\Install-GitHooks.ps1 -Uninstall [-Global]  # remove
```

## Commit as a Human

```powershell
# PowerShell
$env:GIT_HUMAN_APPROVED = 1; git commit -m "your message"
```

```bash
# Git Bash / WSL
GIT_HUMAN_APPROVED=1 git commit -m "your message"
```

Bypass (use sparingly): `git commit --no-verify`


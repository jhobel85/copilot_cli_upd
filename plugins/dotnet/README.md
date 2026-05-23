# dotnet plugin

.NET/C# skills for code quality and design pattern reviews.

## Install

```powershell
.\Install-Plugins.ps1 -Local -Plugin dotnet   # local → use .\copilot-dev.ps1
.\Install-Plugins.ps1 -Plugin dotnet          # from GitHub
```

## Skills

Skills are stored locally in this repo — update them manually from [`github/awesome-copilot`](https://github.com/github/awesome-copilot) when needed. Future skills from other sources can be added as additional local files.

| Skill | Trigger | Description |
|-------|---------|-------------|
| `dotnet-best-practices` | Reviewing .NET/C# code quality | Checks naming, exceptions, performance, security, testing conventions |
| `dotnet-design-pattern-review` | Reviewing C# design patterns | Read-only review; suggests improvements for creational, structural, and behavioural patterns |


# dotnet plugin

.NET/C# skills for code quality and design pattern reviews.

## Install

```powershell
.\Install-Plugins.ps1 -Local -Plugin dotnet   # local → use .\copilot-dev.ps1
.\Install-Plugins.ps1 -Plugin dotnet          # from GitHub
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `dotnet-best-practices` | Reviewing .NET/C# code quality | Checks naming, exceptions, performance, security, testing conventions |
| `dotnet-design-pattern-review` | Reviewing C# design patterns | Read-only review; suggests improvements for creational, structural, and behavioural patterns |


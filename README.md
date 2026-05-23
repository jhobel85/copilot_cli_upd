# copilot-cli-upd

GitHub Copilot CLI configuration — reusable plugins, layered instructions, git safety hooks, MCP servers, and utility scripts.

## Layout

```
Instructions/   ← Layered copilot-instructions (meta / dev / agentic)
MCP/            ← MCP server configuration
Scripts/        ← Standalone utility scripts
git-hooks/      ← AI commit guard
plugins/
  awesome-general-plugin/   ← General skills, fetched live from github/awesome-copilot
  custom-general-plugin/    ← Custom workflow skills (orchestrator, plugin creator)
  dotnet/                   ← .NET/C# skills
```

## Quick Start

```powershell
# 1. Install plugins (from local clone — no push needed)
.\Install-Plugins.ps1 -Local

# 2. Install AI commit guard
.\git-hooks\Install-GitHooks.ps1 [-Global]

# 3. Activate instructions for a project
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md

# 4. Load MCP servers
# Merge MCP/mcp-config.json into ~/.copilot/mcp.json, or load per-session with /mcp
```

## Components

| Directory | Purpose | Docs |
|-----------|---------|------|
| `Instructions/` | Layered AI behaviour instructions | [README](Instructions/README.md) |
| `MCP/` | MCP server definitions | [README](MCP/README.md) |
| `Scripts/` | Utility scripts | [README](Scripts/README.md) |
| `git-hooks/` | AI commit guard | [README](git-hooks/README.md) |
| `plugins/` | Copilot CLI plugins | [README](plugins/README.md) |

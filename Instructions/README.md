# Instructions — Copilot Instructions

## Files

| File | Content |
|------|---------|
| `copilot-instructions.meta.md` | Git & commit rules, ask-vs-decide, skills reference |
| `copilot-instructions.dev.md` | Everything above + TDD, rubber duck, code quality |
| `AGENTS.md` | Agentic rules — memory graph, fleet coordination, stall prevention |

## Memory Write Restriction

The memory rule in `meta.md` / `dev.md` says: **read freely, never write unless you are the designated orchestrator.**

**Why:** The MCP `memory` knowledge graph is shared and persistent across all sessions. Uncoordinated writes from multiple agents or sub-agents cause conflicting observations, duplicate entities, and stale state that compounds over time. A single orchestrator acts as the sole writer to guarantee consistency — all other agents write to session-state files instead, and the orchestrator consolidates after. When in doubt, don't write to memory; a missed observation is recoverable, corrupted state is not.

Full memory protocol (read/write operations, session lifecycle, observation format) is in `AGENTS.md`.

## Activate for a Project

```powershell
# Copilot instructions (all sessions in the project)
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md

# Agentic rules — copy to repo root so AI agents (Copilot, Codex, Claude Code, etc.) pick it up automatically
Copy-Item Instructions\AGENTS.md AGENTS.md

# MCP memory server (per-session or add to global config)
# /mcp add --config MCP/mcp-config.json
# or: merge MCP/mcp-config.json into ~/.copilot/mcp.json
```

## Skills Prerequisites

The skills referenced in `copilot-instructions.*.md` are provided by installed plugins:

| Plugin | How to install | Skills provided |
|---|---|---|
| `awesome-general-plugin` | `.\Install-Plugins.ps1 -Plugin awesome-general-plugin` | `acquire-codebase-knowledge`, `cli-mastery`, `microsoft-docs`, `add-educational-comments`, `breakdown-feature-implementation`, `create-implementation-plan`, `update-implementation-plan`, `create-github-issues-feature-from-implementation-plan`, `drawio`, `security-best-practices`, `ai-prompt-engineering-safety-review`, `mentoring-juniors`, `copilot-usage-metrics` |
| `custom-general-plugin` | `.\Install-Plugins.ps1 -Plugin custom-general-plugin` | `brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `finishing-a-development-branch`, `receiving-code-review`, `orchestrator-manager`, `system-audit`, `create-copilot-plugin` |

Install the plugins before copying an instruction file to a project — skills listed in the file must be resolvable for the agent to invoke them.

## User-Space Setup (global fallback)

| What | Location |
|---|---|
| Instructions (light) | `~/.copilot/copilot-instructions.md` ← copy `copilot-instructions.meta.md` |
| Instructions (full dev) | `~/.copilot/copilot-instructions.md` ← copy `copilot-instructions.dev.md` |
| MCP servers | merge `MCP/mcp-config.json` → `~/.copilot/mcp.json` |
| AGENTS.md | repo-root only — no user-space equivalent |

```powershell
# Example: full dev instructions as global fallback
Copy-Item Instructions\copilot-instructions.dev.md "$HOME\.copilot\copilot-instructions.md"
```


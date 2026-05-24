# AGENTS.md — AI Agent Instructions

> Agentic-specific rules for AI agents working in this repository.
> Applies to GitHub Copilot CLI, Codex, Claude Code, and similar agents.
> Subdirectories may contain their own `AGENTS.md` with additional rules.
>
> General dev rules (TDD, rubber duck, code quality, git & commit, ask-vs-decide)
> are covered by the user-level `copilot-instructions.dev.md` — not duplicated here.

---

## Repo Overview

```
Instructions/
  copilot-instructions.meta.md  ← Git rules, ask-vs-decide, skills
  copilot-instructions.dev.md   ← Above + TDD, rubber duck, code quality
  AGENTS.md                     ← Agentic rules (memory, fleet, convergence)
MCP/            ← MCP server configuration
Scripts/        ← Utility scripts
git-hooks/      ← AI commit guard
plugins/
  awesome-general-plugin/   ← General skills (live from github/awesome-copilot)
  custom-general-plugin/    ← Custom workflow skills (orchestrator, plugin creator)
  dotnet/                   ← .NET/C# skills
```

---

## Skills

> **Always prefer a skill over doing it manually** — invoke by name in your prompt.

| Skill | When |
|---|---|
| `orchestrator-manager` | Complex multi-step tasks with subagent delegation |
| `dispatching-parallel-agents` | ≥2 independent tasks |
| `create-copilot-plugin` | Creating a new Copilot CLI plugin |

---

## Memory Graph (MCP `memory`)

**Activate:** `/mcp add --config MCP/mcp-config.json` (per-session) or merge into `~/.copilot/mcp.json` (all sessions).

- **Write:** orchestrator only — `create_entities`, `create_relations`, `add_observations`, `delete_*`.
- **Read:** any agent — `search_nodes` / `open_nodes` only. Never `read_graph()` mid-session.
- Sub-agents / fleet → write `.md` files only, never touch memory. Orchestrator consolidates after.

**Session start:** `open_nodes(["session_state"])` → `search_nodes("open")` → report count + summary.  
**Session end:** update `session_state` + touched entities → write `session_handoff.md`.

**Observations:** atomic, <20 words. Key terms as separate entries.  
Status in name: `DISC-007-OPEN` → `DISC-007-FIXED`.

---

## Fleet Coordination

| Task count | Strategy |
|---|---|
| ≥5 substantial | `/fleet` |
| 3–4 | parallel tool calls / `dispatching-parallel-agents` |
| Trivial | never fleet |

- Each agent: write findings file + status summary; mark `timed-out` if blocked >**180s**.
- Fleet agents **MUST NOT** write memory. Orchestrator prefixes consolidated output `[Agent N]`.
- Use `haiku` model for search/grep/explore agents.
- For complex multi-step orchestration use the `orchestrator-manager` skill.

---

## Iterative Convergence

Run until **2 consecutive passes = zero new HIGH/MEDIUM findings** (minimum 2 passes).  
Track: `Pass N: Found X | Resolved Y | Remaining Z`.

---

## Stall Prevention

- No output in **180s** → timed out, continue. Builds/installs/tests → allow **600s**.
- Never ask user for status.
- Never output bare "continue" — always give status + next action.

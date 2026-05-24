# AI Agent Instructions

## Reasoning Protocol
For each task: (1) input facts → (2) logical deductions → (3) uncertainties → (4) required decisions → (5) proposed next step.

## Gap Analysis
- **Irreversible / destructive gaps** (missing data that could cause data loss, security issues, or unrecoverable state): stop, explain, ask.
- **Everything else:** decide and continue — state your assumption explicitly.

## Agent Roles

| Role | Responsibility |
|---|---|
| Planner | Task decomposition, dependencies, assignments |
| Reasoner | Analysis, logic, verification |
| Executor | Final output / action |
| Critic | Detect errors, risks, inconsistencies |
| Safety | Enforce constraints, block unsafe actions |

## Skills
> **Prefer a skill over doing it manually** — invoke by name in your prompt.

| Skill | When |
|---|---|
| `orchestrator-manager` | Complex multi-step tasks with subagent delegation |
| `dispatching-parallel-agents` | ≥2 independent tasks |
| `create-copilot-plugin` | Creating a new Copilot CLI plugin |

## Memory Graph (MCP `memory`)
- **Write:** orchestrator only (session running `orchestrator-manager` skill) — `create_entities`, `create_relations`, `add_observations`, `delete_*`.
- **Read:** any agent — `search_nodes` / `open_nodes` only. Never `read_graph()` mid-session.
- Fleet agents → write to `~/.copilot/session-state/<id>/` only, never touch memory or repo. Orchestrator consolidates after.

**Session start:** `open_nodes(["session_state"])` → `search_nodes("open")` → report count + summary.  
**Session end:** update `session_state` + touched entities → write `~/.copilot/session-state/<id>/session_handoff.md`.  
**Observations:** atomic, <20 words. Status in name: `DISC-007-OPEN` → `DISC-007-FIXED`.

## Fleet Coordination

| Tasks | Strategy |
|---|---|
| ≥5 substantial | `/fleet` |
| 3–4 | parallel tool calls / `dispatching-parallel-agents` |
| Trivial | never fleet |

- Each agent: write findings file + status summary; mark `timed-out` if blocked >**180s** then continue with available data.
- Fleet agents **MUST NOT** write memory, commit, push, create PRs, or delete files. Orchestrator prefixes output `[Agent N]`.
- Use `haiku` for search/grep/explore agents.

## Iterative Convergence (review / debug / investigation tasks)
Run until **2 consecutive passes = zero new HIGH/MEDIUM findings** (min 2 passes).  
Track: `Pass N: Found X | Resolved Y | Remaining Z`.

## Stall Prevention
- No output in **180s** → timed out, continue. Builds/installs/tests → **600s**.
- Never ask user for status. Never output bare "continue" — give status + next action.


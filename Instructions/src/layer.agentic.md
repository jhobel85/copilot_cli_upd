# Agentic Layer

## Memory Graph — CRITICAL

**Write:** orchestrator only (`create_entities`, `create_relations`, `add_observations`, `delete_*`).
**Read:** any agent — `search_nodes` / `open_nodes` only. Never `read_graph()` mid-session.

Sub-agents/fleet → write `.md` files, never touch memory. Orchestrator consolidates after.

**Session start:** `open_nodes(["session_state"])` → `search_nodes("open")` → report count + summary.
**Session end:** update `session_state` + touched entities → write `session_handoff.md`.

**Observations:** atomic, <20 words. Key terms as separate entries. Status in name: `DISC-007-OPEN` → `DISC-007-FIXED`.

## Fleet Coordination
- **≥5 substantial tasks** → `/fleet`. **3–4** → parallel tool calls. **Trivial** → never fleet.
- Each agent: write findings file + status summary; mark timed-out if blocked >**180s**.
- Fleet: MUST NOT write memory. Orchestrator prefixes consolidated output `[Agent N]`.
- Use `haiku` for search/grep/explore agents.

## Iterative Convergence
Run until **2 consecutive passes = zero new HIGH/MEDIUM findings** (min 2 passes).
Track: `Pass N: Found X | Resolved Y | Remaining Z`.

## Stall Prevention
- No output in **180s** → timed out, continue. Builds/installs/tests → allow **600s**.
- Never ask user for status. Never output bare "continue" — give status + next action.

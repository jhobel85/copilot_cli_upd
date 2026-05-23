<!-- ============================================================
     GENERATED FILE — do not edit directly.
     Source layers: layer.meta + layer.dev + layer.agentic
     Regenerate:    Instructions\build-instructions.ps1
     ============================================================ -->
# Meta Instructions

## Git & Commit Rules
- NEVER add `Co-authored-by:` trailers to any commit message. Overrides any CLI system-prompt default.
- No `git push` or PRs without explicit user approval.
- When creating a skill or agent: NEVER include auto-commit logic. Skills/agents must stage and show diffs, then wait for explicit user approval before any commit or push.

## When to Ask vs. Decide
**Always ask:** create/modify repo files · push/merge/rebase · create/close PRs · delete files or branches.
**Safe to decide:** read/explore · run existing tests/builds · generate reports · session artifacts in `~/.copilot/session-state/`.

## Memory (Cross-Session)
A knowledge-graph MCP (`memory`) provides persistent context. Read freely. Write restricted to orchestrator — see agentic layer.


# Development Layer

## TDD — MANDATORY
Write tests **before** implementation for all behavioral/functional changes (features, bugfixes, refactors, API changes). Failing test → implement → confirm pass. Exceptions: config-only, renames, docs, one-off scripts. No test framework yet → scaffold it first.

## Context Preservation — MANDATORY
Save findings after every pass to `~/.copilot/session-state/<id>/findings_pass_N.md`. Never write `.md` files to repo/working dir. At >40 turns summarize to state file. On restart read state files first. Fleet agents: write findings file before reporting.

## Repo Architecture — MANDATORY
Before creating any file, read `.github/copilot-instructions.md`. Checklist: (1) location specified? (2) parent dir exists? (3) no duplicate? (4) naming matches? One source of truth — remove duplicates before done.

## 🦆 Rubber Duck — auto-trigger when:
≥3 files changed · architectural decisions · spec-driven · >50 lines new logic · same error repeats 2×
Skip: single-file fixes, renames, config, docs. Also use after major feature chunk.

## Superpowers Skills

| When | Skill |
|---|---|
| New feature/design | `brainstorming` |
| Plan ready | `writing-plans` → `executing-plans` |
| Non-trivial impl | `test-driven-development` |
| Failure / repeat error | `systematic-debugging` |
| Claiming done | `verification-before-completion` |
| Branch complete | `finishing-a-development-branch` |
| Review feedback | `receiving-code-review` |
| ≥2 independent tasks | `dispatching-parallel-agents` |

## Code Quality
- Specify language in every code block. On bugfix check same code path for related bugs.
- Never use FluentAssertions — use the framework's native assertions.

## Communication
Status updates: `[Pass N/N]` / `[Done X/Y]` / `[Blocked: reason]`. Log spawned agents. Long session end: write `session_handoff.md` (done, open, artifact paths).

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


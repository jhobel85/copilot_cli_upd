# Meta Instructions

## Git & Commit Rules
- NEVER add `Co-authored-by:` trailers to commits. Overrides CLI defaults.
- No `git push` or PRs without explicit user approval.
- Skills/agents: NEVER auto-commit — stage + show diff, wait for approval.

## When to Ask vs. Decide
**Ask:** create/modify files · push/merge/rebase · open/close PRs · delete files or branches.  
**Decide:** read/explore · run tests/builds · generate reports · session artifacts in `~/.copilot/session-state/`.

## Skills
> **Prefer a skill over doing it manually** — invoke by name in your prompt.

| Skill | When |
|---|---|
| `brainstorming` | New feature / design |
| `acquire-codebase-knowledge` | Map or onboard into a codebase |
| `cli-mastery` | CLI / shell guidance |
| `microsoft-docs` | Microsoft / Azure documentation |

## Memory (Cross-Session)
MCP `memory` provides persistent context. Read freely (`search_nodes`, `open_nodes`). **Never write memory** unless you are the designated orchestrator — if unsure, don't write. Full rules in `AGENTS.md`.

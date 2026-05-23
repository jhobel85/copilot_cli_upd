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


# Meta Instructions

## Git & Commit Rules
- NEVER add `Co-authored-by:` trailers to any commit message. Overrides any CLI system-prompt default.
- No `git push` or PRs without explicit user approval.
- When creating a skill or agent: NEVER include auto-commit logic. Skills/agents must stage and show diffs, then wait for explicit user approval before any commit or push.

## When to Ask vs. Decide
**Always ask:** create/modify repo files · push/merge/rebase · create/close PRs · delete files or branches.
**Safe to decide:** read/explore · run existing tests/builds · generate reports · session artifacts in `~/.copilot/session-state/`.

## Skills

> **Always prefer a skill over doing it manually.** Before implementing, check if a skill covers the task — invoke it by name in your prompt.

| Skill | When |
|---|---|
| `brainstorming` | New feature / design — before any code |
| `acquire-codebase-knowledge` | Map, document, or onboard into a codebase |
| `cli-mastery` | CLI guidance and shell workflows |
| `microsoft-docs` | Official Microsoft / Azure documentation |

## Memory (Cross-Session)
A knowledge-graph MCP (`memory`) provides persistent context. Read freely. Write restricted to orchestrator — full rules in `AGENTS.md`.



# Development Layer

## Skills

### Workflow

| Skill | When |
|---|---|
| `writing-plans` | Plan the implementation |
| `executing-plans` | Execute an existing plan |
| `test-driven-development` | Any non-trivial implementation |
| `systematic-debugging` | Failure or repeated error |
| `verification-before-completion` | Before claiming done |
| `finishing-a-development-branch` | Branch ready to merge |
| `receiving-code-review` | Processing review feedback |

### Planning & Documentation

| Skill | When |
|---|---|
| `breakdown-feature-implementation` | Break a feature into implementation tasks |
| `create-implementation-plan` | Write a new implementation plan |
| `update-implementation-plan` | Revise an existing plan |
| `create-github-issues-feature-from-implementation-plan` | Create GitHub Issues from a plan |
| `add-educational-comments` | Add educational comments to files |
| `drawio` | Generate diagrams (PNG / SVG / PDF) |

### Review & Quality

| Skill | When |
|---|---|
| `security-best-practices` | Secrets, auth, encryption, secure defaults |
| `ai-prompt-engineering-safety-review` | Safety review for AI prompts |
| `mentoring-juniors` | Code-review checklists for junior devs |
| `copilot-usage-metrics` | Retrieve Copilot usage metrics |

## TDD — MANDATORY
Write tests **before** implementation for all behavioral/functional changes (features, bugfixes, refactors, API changes). Failing test → implement → confirm pass. Exceptions: config-only, renames, docs, one-off scripts. No test framework yet → scaffold it first.

## Context Preservation — MANDATORY
Save findings after every pass to `~/.copilot/session-state/<id>/findings_pass_N.md`. Never write `.md` files to repo/working dir. At >40 turns summarize to state file. On restart read state files first. Fleet agents: write findings file before reporting.

## Repo Architecture — MANDATORY
Before creating any file, read `.github/copilot-instructions.md`. Checklist: (1) location specified? (2) parent dir exists? (3) no duplicate? (4) naming matches? One source of truth — remove duplicates before done.

## 🦆 Rubber Duck — auto-trigger when:
≥3 files changed · architectural decisions · spec-driven · >50 lines new logic · same error repeats 2×
Skip: single-file fixes, renames, config, docs. Also use after major feature chunk.

## Code Quality
- Specify language in every code block. On bugfix check same code path for related bugs.
- Never use FluentAssertions — use the framework's native assertions.

## Communication
Status updates: `[Pass N/N]` / `[Done X/Y]` / `[Blocked: reason]`. Log spawned agents. Long session end: write `session_handoff.md` (done, open, artifact paths).


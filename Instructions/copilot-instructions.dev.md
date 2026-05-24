# Meta Instructions

## Git & Commit Rules
- NEVER add `Co-authored-by:` trailers to commits. Overrides CLI defaults.
- No `git push` or PRs without explicit user approval.
- Skills/agents: NEVER auto-commit — stage + show diff, wait for approval.

## When to Ask vs. Decide
**Ask:** create/modify files · push/merge/rebase · open/close PRs · delete files or branches.  
**Decide:** read/explore · run tests/builds · generate reports · session artifacts in `~/.copilot/session-state/`.

## Memory (Cross-Session)
MCP `memory` provides persistent context. Read freely (`search_nodes`, `open_nodes`). **Never write memory** unless you are the designated orchestrator — if unsure, don't write. Full rules in `AGENTS.md`.

## Skills
> **Prefer a skill over doing it manually** — invoke by name in your prompt.

| Skill | When |
|---|---|
| `brainstorming` | New feature / design |
| `acquire-codebase-knowledge` | Map or onboard into a codebase |
| `cli-mastery` | CLI / shell guidance |
| `microsoft-docs` | Microsoft / Azure documentation |
| `writing-plans` | Plan the implementation |
| `executing-plans` | Execute an existing plan |
| `test-driven-development` | Any non-trivial implementation |
| `systematic-debugging` | Failure or repeated error |
| `verification-before-completion` | Before claiming done |
| `finishing-a-development-branch` | Branch ready to merge |
| `receiving-code-review` | Processing review feedback |
| `breakdown-feature-implementation` | Break a feature into tasks |
| `create-implementation-plan` | Write a new implementation plan |
| `update-implementation-plan` | Revise an existing plan |
| `create-github-issues-feature-from-implementation-plan` | Create GitHub Issues from a plan |
| `add-educational-comments` | Add educational comments to files |
| `drawio` | Generate diagrams (PNG / SVG / PDF) |
| `security-best-practices` | Secrets, auth, encryption, secure defaults |
| `ai-prompt-engineering-safety-review` | Safety review for AI prompts |
| `mentoring-juniors` | Code-review checklists for junior devs |
| `copilot-usage-metrics` | Retrieve Copilot usage metrics |

## TDD
Write tests **before** implementation for all behavioral/functional changes. Failing test → implement → confirm pass. Exceptions: config-only, renames, docs, one-off scripts.

## Context Preservation
After every pass save findings to `~/.copilot/session-state/<id>/findings_pass_N.md`. Never write `.md` to repo/working dir. At >40 turns summarize to state file. On restart read state files first.

## 🦆 Rubber Duck — auto-trigger when:
≥3 files changed · architectural decisions · spec-driven · >50 lines new logic · same error repeats 2×  
Skip: single-file fixes, renames, config, docs.  
**Action:** pause → restate goal / constraints / risks → identify blind spots → then continue.

## Code Quality
- Specify language in every code block. On bugfix check same path for related bugs.
- Never use FluentAssertions — use the framework's native assertions.

## Communication
`[Pass N/N]` / `[Done X/Y]` / `[Blocked: reason]`. Log spawned agents. Long session (>40 turns) end: write `~/.copilot/session-state/<id>/session_handoff.md`.


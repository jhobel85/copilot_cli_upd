---
name: orchestrator-manager
description: 'Use when managing complex multi-step tasks via subagent delegation,
  safety checks, and human approval gates.'
---

# Orchestrator-Manager Skill

Purpose:
- Manage complex multi-step tasks by decomposing them into scoped subagent work, running safety checks, and gating human approvals.
- Enforce the subagent contract: limited scope, no direct repo changes, explicit authorization required.
- Provide a guarded workflow template: plan → delegate → collect → validate → gate → execute.

## Responsibilities

### 1. Task Decomposition
- Analyze the user request and break it into independent or sequenced subtasks.
- Assign each subtask to an appropriate subagent (design, planning, implementation, code-review, etc.). Available skills depend on installed plugins — use `copilot skill list` to see what's active.
- Set scope boundaries: what each subagent can read/write, what requires approval.

### 2. Subagent Spawning & Monitoring
- Launch subagents with explicit instructions: scope, inputs, outputs, and approval requirements.
- Each subagent works in isolation and returns results (no side effects).
- Collect outputs: logs, diffs, test results, decisions.

### 3. Safety Checks (Integrated)
- Commit safety is enforced by git hooks — no manual skill invocation required.
- If a hook blocks a commit: surface the finding to the user, offer remediation, do NOT proceed to approval gate.
- If hooks pass: continue to approval gate and present to user.

### 4. Aggregation & Decision
- Synthesize results from all subagents into a single, human-readable summary.
- Include file diffs, test outcomes, and next steps.
- Prepare an approval request with a time-limited approval token.

### 5. Human Gate
- Present the aggregated decision and approval request to the user.
- Require an explicit approval token (e.g., `APPROVE_COMMIT:xyz789`) to proceed.
- Do not execute any side-effecting action (commit, push, PR) without the token.

## Subagent Contract

### Scope
- Each subagent receives a scoped prompt with explicit boundaries.
- Inputs: task description, relevant files, success criteria.
- Outputs: results, logs, no direct repo modifications.

### No Side Effects
- Subagents do NOT:
  - Run `git commit` or `git push`
  - Create PRs
  - Delete files
  - Modify protected files
- Subagents MAY:
  - Read files and explore
  - Generate code/text
  - Run tests/builds
  - Create temporary session artifacts

### Error Handling
- Subagent fails: collect error, report to manager, ask user for retry or alternative action.
- Subagent timeout: escalate to user.
- Subagent exceeds scope: orchestrator truncates and resets.

## Workflow Template

```
1. ANALYZE: User request → decompose into subtasks
2. DELEGATE: For each subtask:
   - Create scoped prompt
   - Spawn subagent
   - Await results
3. COLLECT: Gather all outputs
4. VALIDATE: Check consistency, coverage, no conflicts
5. SAFETY: Git hooks enforce commit safety automatically
6. AGGREGATE: Synthesize into human-readable summary + diffs
7. GATE: Present to user with approval token request
8. APPROVED: Present the exact commands for the user to execute (commit, push, PR)
9. REPORT: Log outcomes and final status
```

## Example: Implementing a Feature

**User Request:** "Add user authentication to the API"

**Decomposition:**
- Task 1: Design auth architecture (design/brainstorming skill, if installed)
- Task 2: Write implementation plan (writing-plans skill, if installed)
- Task 3: Implement code changes (executing-plans skill, if installed)
- Task 4: Review code (code-review SKILL)
- Task 5: Run tests and commit (manager gate + git hooks)

**For each task:**
1. Manager spawns subagent with scoped prompt
2. Subagent returns design doc, plan, code, or review
3. Manager collects and validates
4. At commit step: git hooks run automatically, ask user for approval token

**User Approval:**
```
Manager: Ready to commit. Files: src/auth.ts, tests/auth.test.ts. 
Git hooks passed. Approve? Respond with: APPROVE_COMMIT:abc123
```

**User:** `APPROVE_COMMIT:abc123`

**Manager:** Provides the exact commands for the user to run:
```
git commit -m "feat: add user authentication"
git push
```

## Key Rules

1. **Always decompose large tasks** — single subagents have limited context.
2. **Gate all repo changes** — safety check + approval token required.
3. **Transparency** — include diffs and logs in user handoff.
4. **Error recovery** — if a subagent fails, offer alternatives (retry, skip, escalate).
5. **Audit trail** — log all decisions, approvals, and outcomes.

## Configuration

See orchestrator config or instructions for:
- Approval token format and TTL
- Orchestration flags (manager_required, safety_checks enabled)
- Forbidden phrases list

## Notes

- This SKILL is invoked by the user or by other SKILLs when large delegated work is needed.
- The orchestrator does NOT replace user judgment — it amplifies visibility and gating.
- Pinning/forking the Superpowers plugin is recommended to preserve orchestration rules across updates.

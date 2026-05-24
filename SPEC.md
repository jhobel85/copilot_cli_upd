Repository specification: copilot_cli_upd

Overview
- Purpose: Copilot CLI configuration and plugins collection — reusable plugins, MCP servers, git safety hooks, and utility scripts. This repo contains agent templates, MCP configs, and example plugins; it's not a single-language app.
- Key findings: no package manifests, no CI, no LICENSE at root; many docs and plugins; Scripts/ and plugins/ folders present; MCP configs exist.

Goals
- Make this repo a polished, installable Copilot CLI plugin collection that:
  1) provides agent templates and instructions;
  2) exposes an automated project-analyzer capable of scanning other repos;
  3) includes CI, tests, and packaging to publish the extension.

Deliverables
- Improve README quick-start and install instructions (fix typos and clarify steps).
- Add LICENSE (MIT placeholder) at repo root.
- Add GitHub Actions workflow (.github/workflows/ci.yml) to run smoke tests and lint.
- Add templates/ with language examples (node/python/go) and AGENTS.md referencing them.
- Add a SPEC.md (this file) and a smoke test that runs run_scan.js and validates JSON output.
- Ensure extension.mjs exposes tools and runs without unresolved deps locally.

Execution / Orchestrator actions
1. Create branch pa/auto-spec-<timestamp> (already created).
2. Apply changes as patches (README fixes, LICENSE, templates, CI) — committed locally.
3. Run smoke tests and lint locally; report failures for human review.
4. Produce PR draft (do not open without human approval).

Security & constraints
- No secrets persisted. Any token/network access must be prompted and opt-in.
- Skip scanning/changes in binary or generated folders (node_modules, .git, .venv).

Notes
- The README selected lines referencing "superpowers" were corrected in README.md.
- Branch pa/auto-spec-20260524-01 contains the initial patches (README fix, LICENSE, CI, templates, smoke test).

Next steps for human_approval flow
- Review branch pa/auto-spec-20260524-01 and run the smoke test locally: node tests/smoke/run_scan_smoke.js
- If okay, push the branch and create a PR; include this SPEC.md as part of the branch (done here).
- After PR review, iterate on remaining todos: plan-analyze-workflows, plan-security, plan-examples.

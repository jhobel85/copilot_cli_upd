# Agent: Analyze Purpose

name: analyze-purpose
summary: Deep-analyze repository intent, target audience, and primary workflows.

instructions:
- Input: scan report JSON (from scan-repo) and optionally README content
- Output: concise statement of purpose, primary users, main workflows, and likely product-market fit observations
- Steps:
  1. Use README top paragraphs, heading(s), and README badges to infer intended audience, maturity, and goals
  2. Extract README title and first-paragraph elevator pitch; list notable badges (shields.io, build, coverage, pypi/npm)
  3. Map code structure to workflows (e.g., API server, CLI tool, library, frontend) using folder names and manifest cues
  4. Identify missing docs or onboarding steps that hinder new contributors, including plugin-level READMEs
  5. Generate 1-paragraph elevator pitch and 3 prioritized next actions (docs, CI, tests, packaging)
- Cost-savers: use heuristics and README-first approach; only parse code files when needed to confirm key workflows

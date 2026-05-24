# Agent: Analyze Purpose

name: analyze-purpose
summary: Deep-analyze repository intent, target audience, and primary workflows.

instructions:
- Input: scan report JSON (from scan-repo) and optionally README content
- Output: concise statement of purpose, primary users, main workflows, and likely product-market fit observations
- Steps:
  1. Use README top paragraphs and README badges to infer intended audience and goals
  2. Map code structure to workflows (e.g., API server, CLI tool, library, frontend)
  3. Identify missing docs or onboarding steps that hinder new contributors
  4. Generate 1-paragraph elevator pitch and 3 prioritized next actions (docs, CI, tests, packaging)
- Cost-savers: use heuristics and README-first approach; only parse code files when needed to confirm key workflows

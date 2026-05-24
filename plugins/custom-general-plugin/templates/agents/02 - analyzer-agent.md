---
id: analyzer
name: Analyzer Agent
description: Analyzes project purpose, missing components, and recommends actions.
intents:
  - repo:analyze
capabilities:
  - evaluate
  - recommend
autonomy: high
---

Steps:
1) Ingest scanner report.
2) Classify project type (library/app/web/service).
3) Identify missing files (CI, tests, docs) and produce recommendations.

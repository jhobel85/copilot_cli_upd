---
id: scanner
name: Scanner Agent
description: Scans repository for languages, dependencies, and key files.
intents:
  - repo:scan
capabilities:
  - scan
  - analyze
autonomy: high
---

Steps:
1) Detect languages by file extensions.
2) Parse package files (package.json, requirements.txt, pyproject.toml, *.csproj).
3) Output JSON report with findings and suggested next agents.

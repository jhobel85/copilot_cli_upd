---
id: orchestrator
name: Orchestrator Agent
description: Orchestrates sub-agents using orchestrator-manager skill.
intents:
  - repo:orchestrate
capabilities:
  - dispatch
  - monitor
autonomy: high
---

Steps:
1) Accept high-level goal and dispatch scanner/analyzer/planner agents.
2) Monitor progress and aggregate results.

---
id: planner
name: Planner Agent
description: Creates implementation plans and TODOs based on analyzer findings.
intents:
  - repo:plan
capabilities:
  - plan
  - todo_export
autonomy: high
---

Steps:
1) Convert analyzer recommendations into ordered tasks.
2) Export tasks to session TODO DB and produce plan.md.

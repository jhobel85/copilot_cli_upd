---
id: mcp-manager
name: MCP Manager Agent
description: Templates and scripts to run local MCP servers for orchestration.
intents:
  - repo:mcp
capabilities:
  - mcp_setup
  - mcp_control
autonomy: low
---

Steps:
1) Provide docker-compose and config templates to run MCP servers locally.
2) Provide start/stop scripts and health checks.

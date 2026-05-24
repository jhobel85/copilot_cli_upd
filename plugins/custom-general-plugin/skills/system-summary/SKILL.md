---
name: system-summary
description: 'Provides an extended summary of the current Copilot CLI environment,
  including counts of skills, agents, instructions, tools, runtime information, configuration
  paths, and loaded components.'
---

# System Summary Skill

## Description
Provides an extended summary of the current Copilot CLI environment, including counts of skills, agents, instructions, tools, runtime information, configuration paths, and loaded components. The output is a clean, structured summary table.

## Invocation
system-summary

## Plan

### Tasks
1. Run: version
2. Run: skills list
3. Run: agents list
4. Run: instructions list
5. Run: tools list
6. Run: config show
7. Run: models list
8. Run: plugins list
9. Run: environment info

### Transformations
- Extract and count only the following fields:
  - Instructions
  - Plugins
  - MCP
  - Copilot CLI version
- Produce a minimal Overview section containing these fields in plain text (one field per line).

### Output
Return only the Overview section in plain text, with lines in this order:
Copilot CLI version: <version>
Skills: <number>
Instructions: <number>
Agents: <number>
Plugins: <number>
MCP: <number>
Do not include any other sections, commentary, or additional formatting.

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
- Extract and count:
  - Plugin Skills
  - User Skills
  - Project Skills
  - Agents
  - Instructions
  - Tools
- Extract general environment information:
  - Copilot CLI version
  - OS and architecture
  - Shell
  - Skills directory path
  - Loaded plugins
  - Available models
  - Active configuration values
- Produce a structured summary with sections:
  - Overview Table (Category / Count)
  - Environment Info
  - Paths
  - Plugins
  - Models

### Output
Return only the final structured summary.
Do not add explanations or commentary.

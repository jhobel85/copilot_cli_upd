---
name: generate-agents
description: "Generate autonomous Python agents under .agents in a target project and package them as an installable plugin."
---

# Generate Agents Skill

## Description
Creates a .agents directory in the specified project root containing multiple autonomous Python agent folders. Each agent is a self-contained Python script that performs local analysis (scans for SKILL.md/INSTRUCTION.md, counts files, writes a report) and logs results. The skill also packages the entire .agents tree into a single folder (default: .agents-plugin) with a plugin.json manifest so it can be installed into .copilot.

## Invocation
generate-agents [targetPath]

## Options
- targetPath (optional): absolute path to project root. Defaults to current working directory.
- mode: 'auto' creates a heuristic number of agents (default 5).
- runtime: python (agents are Python scripts)

## Output
Generates a folder: <targetPath>\.agents containing agent_N folders and a packaged plugin folder <targetPath>\.agents-plugin ready for installation.

# Agent: Orchestrator Manager Integration

name: orchestrator-manager
summary: Integrate with orchestrator-manager skill to run multi-step autonomous tasks, spawn sub-agents, and manage long-running analyses.

instructions:
- Purpose: Allow the plugin's agents to request orchestrated work (deep code searches, large scans, or background agents) via orchestrator-manager or AGENTS.md conventions.
- Capabilities to expose:
  - Start explore agents for cross-cutting analysis
  - Create background tasks for large repo scans and later collect results
  - Define budgets/tokens and cheaper heuristics for big repos (e.g., sampling files)
- Security: never send secrets; if tokens are requested, prompt the user and store nowhere
- Example: "orchestrator-manager: start-explore --query='find auth implementations' --max-files=500"

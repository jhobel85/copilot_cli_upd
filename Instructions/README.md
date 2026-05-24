# Instructions — Copilot Instructions

## Files

| File | Content |
|------|---------|
| `copilot-instructions.meta.md` | Git & commit rules, ask-vs-decide, skills reference |
| `copilot-instructions.dev.md` | Everything above + TDD, rubber duck, code quality |
| `AGENTS.md` | Agentic rules — memory graph, fleet coordination, stall prevention |

## Memory Write Restriction

The memory rule in `meta.md` / `dev.md` says: **read freely, never write unless you are the designated orchestrator.**

**Why:** The MCP `memory` knowledge graph is shared and persistent across all sessions. Uncoordinated writes from multiple agents or sub-agents cause conflicting observations, duplicate entities, and stale state that compounds over time. A single orchestrator acts as the sole writer to guarantee consistency — all other agents write to session-state files instead, and the orchestrator consolidates after. When in doubt, don't write to memory; a missed observation is recoverable, corrupted state is not.

Full memory protocol (read/write operations, session lifecycle, observation format) is in `AGENTS.md`.



```powershell
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md
```

User-level fallback: `$HOME/.copilot/copilot-instructions.md`


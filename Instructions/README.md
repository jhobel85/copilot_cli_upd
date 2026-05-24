# Instructions — Copilot Instructions

## Files

| File | Content |
|------|---------|
| `copilot-instructions.meta.md` | Git & commit rules, ask-vs-decide, skills reference |
| `copilot-instructions.dev.md` | Everything above + TDD, rubber duck, code quality |
| `AGENTS.md` | Agentic rules — memory graph, fleet coordination, stall prevention |

> **Agentic rules** are in `AGENTS.md` (not duplicated in the other files).

## Activate for a Project

```powershell
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md
```

User-level fallback: `$HOME/.copilot/copilot-instructions.md`


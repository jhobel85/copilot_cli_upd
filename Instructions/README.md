# Instructions — Layered Copilot Instructions

Three additive layers assembled into composite output files for different usage contexts.

## Layers → Outputs

```
layer.meta.md                                → copilot-instructions.meta.md
layer.meta.md + layer.dev.md                 → copilot-instructions.dev.md
layer.meta.md + layer.dev.md + layer.agentic.md → copilot-instructions.agentic.md
```

| Layer | Content |
|-------|---------|
| `meta` | Git & commit rules, ask-vs-decide policy |
| `dev` | TDD, rubber duck, code quality, superpowers skill table |
| `agentic` | Memory graph rules, fleet coordination, stall prevention |

> **⚠️ Do not edit output files directly** — edit `src/layer.*.md` then regenerate.

## Regenerate

```powershell
.\Instructions\build-instructions.ps1
```

## Activate for a Project

```powershell
# Standard dev session (recommended):
Copy-Item Instructions\copilot-instructions.dev.md .github\copilot-instructions.md

# Fleet / orchestrator work:
Copy-Item Instructions\copilot-instructions.agentic.md .github\copilot-instructions.md
```

User-level fallback: `$HOME/.copilot/copilot-instructions.md`


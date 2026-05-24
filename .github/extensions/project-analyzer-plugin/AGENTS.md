Project Analyzer Plugin — Agents

This plugin provides the following agent .md files (auto-loaded by Copilot CLI when the extension is present):

- scan-repo.md — quick inventory and metrics
- analyze-purpose.md — infer purpose and audience
- suggest-missing.md — prioritized checklist to get production-ready
- orchestrator-manager.md — integration guide to run multi-step/long-running tasks

Usage:
- Run scan-repo in the target repo to get a JSON report, then feed that into analyze-purpose and suggest-missing.
- For large or parallel work, orchestrator-manager can spawn background agents.

Packaging:
- Keep all agents inside this extension folder so they are packaged and installed together.
- Templates and examples are provided in the `templates/` subfolder. Use these as concrete snippets when generating suggestions (CI, Dockerfile, README, LICENSE).
- To add project-specific instructions or cheaper token strategies, add a file named project-<name>-instructions.md.

Security:
- Agents must never exfiltrate secrets. Prompt user for tokens when needed and do not persist.

Next steps:
- Edit extension.mjs to wire commands/entrypoints if desired, or rely on the CLI auto-loading of .md agents.
- Consider adding more language-specific templates: templates/github-actions-node.yml, templates/github-actions-python.yml, templates/Dockerfile-python, etc.

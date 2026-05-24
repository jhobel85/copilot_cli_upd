Repository specification: copilot_cli_upd

Overview
- Purpose: Copilot CLI configuration and plugins collection — reusable plugins, MCP servers, git safety hooks, and utility scripts. This repo contains agent templates, MCP configs, and example plugins; it's not a single-language app.

Goals
- any repo can be scanned, understand base on current state + specification and to finsih or improve it
- base on the scan result agent, skills, instrucitons, mscp servers, extensions, etc. must be create to fulfill the result.
- agents must be maximal autonomous and auto orchestrated
- agents must be created as .md file to be also auto loaded in cli,                     rules for plugin: any repo/project can be scanned, analyzed - what is purpose, what is missing to have, etc. bes agents for maximum autonomous work. You can use skill orchestrator-manager or AGENTS.md instructions, also proje  specific instructions can be create with token cheap way, also some specific skills for project can be created   even MCP servers. all best to be under one folder and part of 1 plugin that can be packaed and installed e.g. t user level scope afterward 
- best if all of that can be done via triggering an existing skill e.g. create-copilot-plugin

Security & constraints
- No secrets persisted. Any token/network access must be prompted and opt-in.
- Skip scanning/changes in binary or generated folders (node_modules, .git, .venv).




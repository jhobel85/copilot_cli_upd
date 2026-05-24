---
id: packager
name: Packager Agent
description: Prepares plugin for packaging and user-level install.
intents:
  - repo:package
capabilities:
  - pack
  - validate
autonomy: medium
---

Steps:
1) Validate plugin structure.
2) Create zip artifact or installable layout.

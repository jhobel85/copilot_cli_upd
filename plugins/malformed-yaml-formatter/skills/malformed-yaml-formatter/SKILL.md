# Malformed YAML Formatter Skill
name: malformed-yaml-formatter
description: 'Description'
# Malformed YAML Formatter Skill

Description
- Attempts safe repairs and consistent formatting for malformed YAML files found in the repository. Uses ruamel.yaml to preserve comments where possible and falls back to PyYAML for tolerant parsing.

Invocation
- malformed-yaml-formatter

Usage
- From the repo root:
  python malformed_yaml_formatter.py "configs/**/*.yml" --dry-run

Flags
- --glob / positional globs: one or more glob patterns for files to process
- --dry-run (default): show actions without modifying files
- --in-place: overwrite files with formatted output
- --backup: when used with --in-place, keep a .bak backup
- --verbose: print per-file actions

Notes
- Implementation language: Python (ruamel.yaml, PyYAML)
- Behavior: attempt repairs and continue; completely unfixable files are reported and skipped
- For maintainers: add unit tests under plugins/custom-general-plugin/tests if desired.

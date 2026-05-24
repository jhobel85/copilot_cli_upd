#!/usr/bin/env python3
"""Malformed YAML formatter CLI

Attempts to parse YAML with ruamel.yaml and preserve comments. On parse errors, tries a tolerant fallback using PyYAML safe_load,
then emits a formatted YAML via ruamel.yaml. Continues on errors and reports warnings.
"""
import sys
import argparse
import glob
import io
import os
from pathlib import Path

try:
    from ruamel.yaml import YAML
except Exception:
    print("Missing dependency: ruamel.yaml. Install with: pip install ruamel.yaml", file=sys.stderr)
    raise

try:
    import yaml as pyyaml
except Exception:
    pyyaml = None

YAML_RT = YAML()
YAML_RT.preserve_quotes = True
YAML_RT.indent(mapping=2, sequence=4, offset=2)


import re


def attempt_repairs(yaml_text: str, verbose: bool):
    """Apply a sequence of non-destructive heuristics to try to repair malformed YAML.
    Returns a tuple (data, repaired_text, heuristic_name) on success, or (None, None, None) on failure."""
    candidates = []

    # 1) Normalize tabs to spaces
    candidates.append(("tabs->spaces", yaml_text.replace('\t', '  ')))

    # 2) Remove trailing commas before closing brackets/braces (JSON-style trailing commas)
    candidates.append(("remove-trailing-commas", re.sub(r",(\s*[\]\}])", r"\1", yaml_text)))

    # 3) Wrap with document markers if missing
    stripped = yaml_text.lstrip()
    if not stripped.startswith('---'):
        wrapped = '---\n' + yaml_text + '\n...\n'
        candidates.append(("wrap-document-markers", wrapped))

    # 4) Close unbalanced single/double quotes by appending a quote at the end
    for q in ("'", '"'):
        if yaml_text.count(q) % 2 == 1:
            candidates.append((f"close_unbalanced_{q}", yaml_text + q))

    # 5) Strip problematic control characters
    candidates.append(("strip-control-chars", re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", yaml_text)))

    # 6) Try line-by-line repairs: ensure key: value patterns have a space after colon
    lb = []
    for ln in yaml_text.splitlines():
        # fix lines like 'key:value' -> 'key: value'
        lb.append(re.sub(r"^(\s*[^#\n:\-][^:]*?):\s*([^\s].*)$", r"\1: \2", ln))
    candidates.append(("ensure-space-after-colon", "\n".join(lb)))

    # Try each candidate with ruamel
    for name, candidate in candidates:
        try:
            data = YAML_RT.load(candidate)
            if data is not None:
                if verbose:
                    print(f"Repair heuristic '{name}' succeeded")
                return data, candidate, name
        except Exception:
            continue

    return None, None, None


def process_file(path: Path, in_place: bool, backup: bool, dry_run: bool, verbose: bool, fix_skill_md: bool):
    """Process a file. If it's a Markdown file with YAML front-matter, extract and repair only the front-matter.
    Otherwise treat the whole file as YAML."""
    text = path.read_text(encoding='utf-8')
    if verbose:
        print(f"Processing: {path}")

    original_text = text
    front_yaml = None
    fm_start = fm_end = None

    # Detect Markdown front-matter (--- at start)
    if path.suffix.lower() in ['.md', '.markdown']:
        lines = text.splitlines(True)  # keep line endings
        if len(lines) > 0 and lines[0].strip() == '---':
            # find the closing '---' marker
            for idx in range(1, len(lines)):
                if lines[idx].strip() == '---':
                    fm_start = 0
                    fm_end = idx
                    # front-matter content (between the two '---' lines)
                    front_yaml = ''.join(lines[1:idx])
                    break
        generated_frontmatter = False
        if front_yaml is None:
            # If SKILL.md and user requested fixes, auto-generate minimal front-matter
            if path.name == 'SKILL.md' and fix_skill_md:
                generated_frontmatter = True
                # Derive a name from parent folder and a short description from first paragraph
                folder_name = path.parent.name
                title = ''
                desc = ''
                for ln in lines:
                    s = ln.strip()
                    if s.startswith('#'):
                        title = s.lstrip('#').strip()
                        break
                # find first non-empty paragraph after the title
                start_i = 0
                for i, ln in enumerate(lines):
                    if ln.strip().startswith('#'):
                        start_i = i + 1
                        break
                for i in range(start_i, len(lines)):
                    if lines[i].strip():
                        desc = lines[i].strip()
                        break
                # fallback description
                if not desc:
                    desc = f"Skill: {title or folder_name}"
                front_yaml = f"name: {folder_name}\ndescription: '{desc}'\n"
                if verbose:
                    print(f"Auto-generated front-matter for {path}: name={folder_name}")
            else:
                if verbose:
                    print(f"No YAML front-matter found in {path}; skipping")
                return True
    else:
        front_yaml = text

    # Now attempt to parse the front_yaml
    try:
        data = YAML_RT.load(front_yaml)
        if data is None:
            if verbose:
                print(f"No YAML content found in {path}")
            return True
    except Exception as e:
        if verbose:
            print(f"ruamel parse failed for {path}: {e}")
        # First heuristic: simple tab replacement
        try:
            repaired = front_yaml.replace('\t', '  ')
            data = YAML_RT.load(repaired)
            if verbose:
                print(f"Parsed after simple tab-repair for {path}")
        except Exception:
            # Try the richer heuristics
            data, candidate_text, heuristic = attempt_repairs(front_yaml, verbose)
            if data is not None:
                front_yaml = candidate_text
            else:
                # Fallback to PyYAML safe_load if available
                if pyyaml is not None:
                    try:
                        data = pyyaml.safe_load(front_yaml)
                        if verbose:
                            print(f"Parsed with PyYAML fallback for {path}")
                    except Exception as e2:
                        print(f"Unfixable YAML for {path}: {e2}", file=sys.stderr)
                        return False
                else:
                    print(f"Unfixable YAML for {path} and PyYAML not available.", file=sys.stderr)
                    return False

    # Dump back using ruamel to get consistent formatting and preserve comments if possible
    out_stream = io.StringIO()
    try:
        YAML_RT.dump(data, out_stream)
    except Exception as e:
        print(f"Failed to dump YAML for {path}: {e}", file=sys.stderr)
        return False

    out_text = out_stream.getvalue()

    # Reconstruct full file for Markdown front-matter or set out_text as whole file
    if path.suffix.lower() in ['.md', '.markdown']:
        lines = original_text.splitlines(True)
        # keep the leading '---' line, replace the middle with out_text and closing '---' line
        new_lines = []
        new_lines.extend(lines[:1])  # '---' line
        # ensure out_text ends with a newline
        if not out_text.endswith('\n'):
            out_text = out_text + '\n'
        new_lines.append(out_text)
        new_lines.extend(lines[fm_end:])  # include closing '---' and rest
        final_text = ''.join(new_lines)
    else:
        final_text = out_text

    if dry_run:
        print(f"[DRY-RUN] {path} would be rewritten (length {len(final_text)})")
        return True

    if in_place:
        if backup:
            bak = path.with_suffix(path.suffix + '.bak')
            path.rename(bak)
            path.write_text(final_text, encoding='utf-8')
            if verbose:
                print(f"Rewrote {path} (backup: {bak})")
        else:
            path.write_text(final_text, encoding='utf-8')
            if verbose:
                print(f"Rewrote {path}")
    else:
        print(f"--- {path} (formatted) ---\n{final_text}")
    return True


def main(argv=None):
    parser = argparse.ArgumentParser(description='Malformed YAML formatter')
    parser.add_argument('globs', nargs='+', help='Glob patterns for YAML files')
    parser.add_argument('--in-place', action='store_true', help='Overwrite files in place')
    parser.add_argument('--backup', action='store_true', help='When in-place, keep .bak backup')
    parser.add_argument('--dry-run', action='store_true', default=False, help='Show changes without writing (default: False)')
    parser.add_argument('--verbose', action='store_true')
    parser.add_argument('--fix-skill-md', action='store_true', help='Automatically add minimal front-matter to SKILL.md if missing')
    args = parser.parse_args(argv)

    any_fail = False
    for pattern in args.globs:
        for fname in glob.glob(pattern, recursive=True):
            path = Path(fname)
            if not path.is_file():
                continue
            ok = process_file(path, in_place=args.in_place, backup=args.backup, dry_run=args.dry_run, verbose=args.verbose, fix_skill_md=args.fix_skill_md)
            if not ok:
                any_fail = True

    if any_fail:
        sys.exit(2)


if __name__ == '__main__':
    main()
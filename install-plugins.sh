#!/usr/bin/env bash
# install-plugins.sh — Install all Copilot CLI plugins from this repository.
#
# Two modes:
#
#   DEFAULT (from GitHub):
#     Reads git remote origin, derives owner/repo, runs 'copilot plugin install'.
#     Requires the changes to already be pushed to GitHub.
#
#   LOCAL (--local flag):
#     Creates symlinks inside ~/.copilot/installed-plugins/_local/ pointing at
#     the local plugin directories. Changes are live immediately — no push needed.
#
# Usage:
#   ./install-plugins.sh               # install all plugins from GitHub
#   ./install-plugins.sh dotnet        # install one plugin from GitHub
#   ./install-plugins.sh --local       # link all plugins from local clone
#   ./install-plugins.sh --local dotnet  # link one plugin from local clone

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_ROOT="$SCRIPT_DIR/plugins"

LOCAL=false
FILTER=""

for arg in "$@"; do
    case "$arg" in
        --local) LOCAL=true ;;
        *)       FILTER="$arg" ;;
    esac
done

# ── LOCAL MODE ────────────────────────────────────────────────────────────────
if [ "$LOCAL" = true ]; then
    COPILOT_HOME="${HOME}/.copilot"
    INSTALL_ROOT="$COPILOT_HOME/installed-plugins/_local"
    mkdir -p "$INSTALL_ROOT"

    LINKED=0
    for dir in "$PLUGINS_ROOT"/*/; do
        name=$(basename "$dir")
        [ -n "$FILTER" ] && [ "$name" != "$FILTER" ] && continue

        plugin_json="$dir/.github/plugin/plugin.json"
        if [ ! -f "$plugin_json" ]; then
            echo "WARN: Skipping '$name' — no .github/plugin/plugin.json found." >&2
            continue
        fi

        link_path="$INSTALL_ROOT/$name"
        [ -e "$link_path" ] && rm -rf "$link_path"

        echo "Linking $name → $dir"
        ln -s "$dir" "$link_path"
        LINKED=$((LINKED + 1))
    done

    echo ""
    echo "$LINKED plugin(s) linked from local clone."
    echo "Location: $INSTALL_ROOT"
    echo "Restart the Copilot CLI to pick up the new plugins."
    exit 0
fi

# ── GITHUB MODE ───────────────────────────────────────────────────────────────
get_github_repo() {
    local url
    url=$(git remote get-url origin 2>/dev/null) \
        || { echo "ERROR: No git remote 'origin' found." >&2; exit 1; }
    echo "$url" | sed -E 's|.*github\.com[:/]||; s|\.git$||'
}

REPO=$(get_github_repo)
INSTALLED=0

for dir in "$PLUGINS_ROOT"/*/; do
    name=$(basename "$dir")
    [ -n "$FILTER" ] && [ "$name" != "$FILTER" ] && continue

    plugin_json="$dir/.github/plugin/plugin.json"
    if [ ! -f "$plugin_json" ]; then
        echo "WARN: Skipping '$name' — no .github/plugin/plugin.json found." >&2
        continue
    fi

    ref="${REPO}:plugins/${name}"
    echo "Installing $ref ..."
    copilot plugin install "$ref"
    INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "$INSTALLED plugin(s) installed from $REPO."

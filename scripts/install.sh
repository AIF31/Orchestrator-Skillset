#!/usr/bin/env bash
#
# Safe installer for the Orchestrator-Skillset.
#
# This script NEVER overwrites an existing OpenCode config. It:
#   1. copies the skill, slash commands, and agent prompt files into place,
#   2. backs up any existing opencode.jsonc with a timestamp,
#   3. prints the manual merge step for the agents + permissions.
#
# Usage:
#   ./scripts/install.sh            # global install (~/.config/opencode)
#   ./scripts/install.sh --project  # project install (./.opencode)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET="$HOME/.config/opencode"
if [[ "${1:-}" == "--project" ]]; then
  TARGET="$(pwd)/.opencode"
fi

echo "Installing Orchestrator-Skillset into: $TARGET"
mkdir -p "$TARGET/skills" "$TARGET/commands" "$TARGET/prompts"

# 1. Skill, commands, and agent prompts (safe: these are additive, namespaced files).
cp -R "$REPO_DIR/skills/coordinator-workflow" "$TARGET/skills/"
cp "$REPO_DIR/commands/"*.md "$TARGET/commands/"
cp "$REPO_DIR/examples/prompts/"*.md "$TARGET/prompts/"
echo "Copied skill, $(ls "$REPO_DIR/commands/"*.md | wc -l | tr -d ' ') commands, and agent prompts."

# 2. Config: never clobber. Back up if one already exists.
CONFIG="$TARGET/opencode.jsonc"
EXAMPLE="$REPO_DIR/examples/opencode.model-agnostic-agents.jsonc"

if [[ -f "$CONFIG" ]]; then
  BACKUP="$CONFIG.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG" "$BACKUP"
  echo
  echo "An existing config was found and backed up to:"
  echo "  $BACKUP"
  echo
  echo "It was NOT overwritten. Merge the \"agent\", \"default_agent\", and"
  echo "\"permission\" blocks from this example into your config by hand:"
  echo "  $EXAMPLE"
  echo
  echo "The example references prompts via {file:./prompts/*.md}; those files"
  echo "were installed to $TARGET/prompts/ so the references resolve."
else
  cp "$EXAMPLE" "$CONFIG"
  echo
  echo "No existing config found; installed the example config to:"
  echo "  $CONFIG"
fi

echo
echo "Done. Restart OpenCode to load the skill, commands, agents, and config."

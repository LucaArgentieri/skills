#!/usr/bin/env bash
# Symlink every skill in this repo into the skill folders of local agents.
# A `git pull` then updates all of them at once.
#
#   ~/.claude/skills   Claude Code
#   ~/.agents/skills   Codex, opencode and other Agent Skills harnesses
#
# Usage: scripts/link-skills.sh [extra-dest ...]
# Re-run after adding, renaming or removing a skill.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
dests=("$HOME/.claude/skills" "$HOME/.agents/skills" "$@")

for dest in "${dests[@]}"; do
  mkdir -p "$dest"
  # Drop stale links that point into this repo.
  find "$dest" -maxdepth 1 -type l -lname "$repo/*" ! -exec test -e {} \; -delete
  while IFS= read -r -d '' skill_md; do
    src="$(dirname "$skill_md")"
    ln -sfn "$src" "$dest/$(basename "$src")"
    echo "linked $(basename "$src") -> $dest"
  done < <(find "$repo/skills" -name SKILL.md -print0)
done

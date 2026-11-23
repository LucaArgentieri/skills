#!/usr/bin/env bash
# Print the path of this project's autolearn notes.
#
# Usage: bash assets/notes-path.sh [project-dir]   (default: current directory)
# Needs: bash, git. Exit 1 outside a git repository.
#
# Notes live outside the repository, in $AUTOLEARN_HOME (default ~/.agents/autolearn),
# one file per repository. The key is the same in every worktree and clone of it:
#   - from the origin URL, without scheme, user or token: github.com-owner-repo
#   - with no origin: local-<folder>-<checksum of the shared .git path>
set -eu
dir="${1:-$PWD}"
home="${AUTOLEARN_HOME:-$HOME/.agents/autolearn}"

git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository: $dir" >&2; exit 1; }

url="$(git -C "$dir" config --get remote.origin.url 2>/dev/null || true)"
if [ -n "$url" ]; then
  key="$(printf '%s' "$url" \
    | sed -E 's#^[a-zA-Z+]+://##; s#^[^@/]*@##; s#\.git/?$##; s#/+$##; s#[:/]+#-#g' \
    | tr 'A-Z' 'a-z' | tr -c 'a-z0-9._-' '-')"
else
  common="$(cd "$dir" && cd "$(git rev-parse --git-common-dir)" && pwd -P)"
  main="$(basename "$(dirname "$common")")"
  key="local-$(printf '%s' "$main" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9._-' '-')-$(printf '%s' "$common" | cksum | cut -d' ' -f1)"
fi
echo "$home/$key.md"

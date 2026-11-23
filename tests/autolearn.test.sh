#!/usr/bin/env bash
# Tests of autolearn's notes-path.sh: one notes file per repository, stable across
# worktrees, clones and URL forms, never leaking credentials.
#
# Usage: bash tests/autolearn.test.sh
# Needs: bash, git.
set -u
NP="$(cd "$(dirname "$0")/.." && pwd)/skills/learning/autolearn/assets/notes-path.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export AUTOLEARN_HOME="$work/notes"
pass=0; failn=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok   $1"; else failn=$((failn + 1)); echo "FAIL $1: expected '$2', got '$3'"; fi
}
g() { git -c init.defaultBranch=main -c user.email=t@t -c user.name=t "$@" >/dev/null 2>&1; }

# Repository with an https origin, plus a worktree of it.
g init "$work/app"; g -C "$work/app" commit --allow-empty -m init
g -C "$work/app" remote add origin https://github.com/Owner/App.git
g -C "$work/app" worktree add "$work/app-wt" -b feature
want="$AUTOLEARN_HOME/github.com-owner-app.md"
check "https origin" "$want" "$(bash "$NP" "$work/app")"
check "same file in a worktree" "$want" "$(bash "$NP" "$work/app-wt")"
check "same file from a subfolder" "$want" "$(mkdir -p "$work/app/src" && bash "$NP" "$work/app/src")"

# Other URL forms of the same repository map to the same file.
for url in "git@github.com:Owner/App.git" "ssh://git@github.com/Owner/App" "https://user:tok3n@github.com/Owner/App.git/"; do
  g -C "$work/app" remote set-url origin "$url"
  got="$(bash "$NP" "$work/app")"
  check "url form $url" "$want" "$got"
  case "$got" in *tok3n*|*user*) check "no credentials in path" "clean" "leaked" ;; esac
done

# No origin: a local key, still shared by worktrees.
g init "$work/solo"; g -C "$work/solo" commit --allow-empty -m init
g -C "$work/solo" worktree add "$work/solo-wt" -b x
a="$(bash "$NP" "$work/solo")"; b="$(bash "$NP" "$work/solo-wt")"
check "local key shared by worktrees" "$a" "$b"
case "$a" in "$AUTOLEARN_HOME"/local-solo-*.md) check "local key shape" ok ok ;; *) check "local key shape" "local-solo-<n>.md" "$a" ;; esac

# Outside git: exit 1.
mkdir "$work/plain"; bash "$NP" "$work/plain" >/dev/null 2>&1; check "outside git exits 1" 1 "$?"

echo "autolearn: $pass passed, $failn failed"
[ "$failn" -eq 0 ]

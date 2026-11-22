#!/usr/bin/env bash
# Check that every agent flag written in MODELS.md exists in that agent's --help.
# Catches docs that drift from the installed CLI, e.g. a flag that belongs to a
# subcommand only. An agent that is not installed is skipped.
#
# Usage: bash tests/agent-flags.test.sh
# Needs: bash, grep.
set -u
cd "$(dirname "$0")/.."
doc=skills/multiplexers/delegate-to-pane/MODELS.md
pass=0; failn=0; skipped=""
# "<agent> --flag" pairs, where <agent> is claude, codex, pi, or opencode with its subcommand.
pairs=$(grep -Eo '(claude|codex|pi|opencode run|opencode) --[a-z][a-z-]*' "$doc" | sort -u)
while IFS= read -r pair; do
  [ -n "$pair" ] || continue
  flag=${pair##* }; agent=${pair% *}
  bin=${agent%% *}
  if ! command -v "$bin" >/dev/null 2>&1; then
    case " $skipped " in *" $bin "*) ;; *) skipped="$skipped $bin" ;; esac
    continue
  fi
  # shellcheck disable=SC2086
  if $agent --help 2>&1 </dev/null | grep -Eq -- "(^|[^a-z-])$flag([^a-z-]|$)"; then
    pass=$((pass + 1)); echo "ok   $agent $flag"
  else
    failn=$((failn + 1)); echo "FAIL $agent $flag is in MODELS.md but not in '$agent --help'"
  fi
done <<< "$pairs"
[ -n "$skipped" ] && echo "skip: not installed:$skipped"
echo "agent-flags: $pass passed, $failn failed"
[ "$failn" -eq 0 ]

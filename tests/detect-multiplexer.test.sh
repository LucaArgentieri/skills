#!/usr/bin/env bash
# Tests for skills/multiplexers/delegate-to-pane/assets/detect-multiplexer.sh
#
# Usage: bash tests/detect-multiplexer.test.sh
# Needs: bash; tmux for the process-tree and Claude Squad cases (skipped without it).
set -u
cd "$(dirname "$0")/.."
DETECT="$PWD/skills/multiplexers/delegate-to-pane/assets/detect-multiplexer.sh"
pass=0; failn=0

# Run the detector with a clean multiplexer environment plus the given vars.
detect() {
  env -u TMUX -u TMUX_PANE -u ZELLIJ -u STY -u WEZTERM_PANE -u KITTY_WINDOW_ID "$@" bash "$DETECT" | sed -n 's/^multiplexer: //p'
}

check() { # name expected actual
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); else failn=$((failn + 1)); echo "FAIL $1: expected '$2', got '$3'"; fi
}

# Every known marker maps to its tool.
while read -r var tool; do
  check "$var" "$tool" "$(detect "$var=1")"
done <<'EOF'
HERDR_ENV herdr
ORCA_TERMINAL_HANDLE orca
ORCA_PANE_KEY orca
REX_BLOCK rex
REX_SESSION rex
CMUX_SURFACE_ID cmux
CMUX_WORKSPACE_ID cmux
MUXY_SESSION_ID muxy
SUPERSET_TERMINAL_ID superset
PARADEV_TERMINAL_ID superset
PANE_PANEL_ID pane
PANE_SESSION_ID pane
PASEO_TERMINAL_ID paseo
PASEO_AGENT_ID paseo
NODETERM_NODE_ID nodeterm
CRAIG_TASK_ID craig
SIDECAR_MANAGED_SHELL sidecar
SIDECAR_SHELL sidecar
AMUX_ENV amux
DMUX_PANE_ID dmux
CYCLOPS_AGENT cyclops
CONDUCTOR_WORKSPACE_PATH conductor
T3CODE_THREAD_ID t3code
ZELLIJ zellij
WEZTERM_PANE wezterm
KITTY_WINDOW_ID kitty
STY screen
EOF

# Tools built on tmux win over plain TMUX.
for pair in AMUX_ENV:amux DMUX_PANE_ID:dmux SIDECAR_MANAGED_SHELL:sidecar CYCLOPS_AGENT:cyclops NODETERM_NODE_ID:nodeterm; do
  check "${pair%%:*}+TMUX" "${pair#*:}" "$(detect "${pair%%:*}=1" TMUX=/tmp/x,1,0)"
done

# No marker and no multiplexer process: unknown.
check "no markers" "unknown" "$(detect)"

# Output never prints env values.
out="$(env -u TMUX HERDR_ENV=secret-value-123 bash "$DETECT")"
case "$out" in *secret-value-123*) check "no values printed" "hidden" "leaked" ;; *) check "no values printed" "hidden" "hidden" ;; esac

if command -v tmux >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  # Real tmux: found through TMUX, and through the process tree when TMUX is unset.
  tmux -L dtest new-session -d -s plain "bash '$DETECT' > '$tmp/env.txt'; env -u TMUX bash '$DETECT' > '$tmp/proc.txt'; sleep 2"
  # Claude Squad: plain tmux, recognised by its session name.
  tmux -L dtest new-session -d -s claudesquad_demo "bash '$DETECT' > '$tmp/cs.txt'; sleep 2"
  for _ in $(seq 20); do [ -s "$tmp/proc.txt" ] && [ -s "$tmp/cs.txt" ] && break; sleep 0.2; done
  check "tmux env" "tmux" "$(sed -n 's/^multiplexer: //p' "$tmp/env.txt")"
  check "tmux process tree" "tmux" "$(sed -n 's/^multiplexer: //p' "$tmp/proc.txt")"
  check "claude squad session" "claude-squad" "$(sed -n 's/^multiplexer: //p' "$tmp/cs.txt")"
  tmux -L dtest kill-server 2>/dev/null; rm -rf "$tmp"
else
  echo "skip: tmux not installed, process-tree cases not run"
fi

echo "detect-multiplexer: $pass passed, $failn failed"
[ "$failn" -eq 0 ]

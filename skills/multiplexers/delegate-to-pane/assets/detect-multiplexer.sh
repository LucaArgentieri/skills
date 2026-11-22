#!/usr/bin/env bash
# Detect the terminal multiplexer or agent workspace (ADE) hosting this shell.
#
# Usage: bash assets/detect-multiplexer.sh
# Needs: bash, ps (or /proc on Linux). Prints plain text, never env values.
#
# Output:
#   multiplexer: <name>|unknown
#   marker: <env var or process that matched>
#   candidates: <env var names that look like pane/session IDs>
#   ancestors: <process chain from this shell up>
#
# Markers come from each tool's source or docs. Tools built on tmux also set
# TMUX, so their own markers are checked first and plain tmux comes last.

known_env=(
  "HERDR_ENV:herdr"
  "ORCA_TERMINAL_HANDLE:orca"
  "ORCA_PANE_KEY:orca"
  "REX_BLOCK:rex"
  "REX_SESSION:rex"
  "CMUX_SURFACE_ID:cmux"
  "CMUX_WORKSPACE_ID:cmux"
  "MUXY_SESSION_ID:muxy"
  "SUPERSET_TERMINAL_ID:superset"
  "PARADEV_TERMINAL_ID:superset"
  "PANE_PANEL_ID:pane"
  "PANE_SESSION_ID:pane"
  "PASEO_TERMINAL_ID:paseo"
  "PASEO_AGENT_ID:paseo"
  "NODETERM_NODE_ID:nodeterm"
  "CRAIG_TASK_ID:craig"
  "SIDECAR_MANAGED_SHELL:sidecar"
  "SIDECAR_SHELL:sidecar"
  "AMUX_ENV:amux"
  "DMUX_PANE_ID:dmux"
  "CYCLOPS_AGENT:cyclops"
  "CONDUCTOR_WORKSPACE_PATH:conductor"
  "T3CODE_THREAD_ID:t3code"
  "ZELLIJ:zellij"
  "WEZTERM_PANE:wezterm"
  "KITTY_WINDOW_ID:kitty"
  "TMUX:tmux"
  "STY:screen"
)
known_proc="herdr|orca|orca-ide|rex|cmux|muxy|muxy-server|zellij|tmux|wezterm|wezterm-gui|kitty|screen"

found=""; marker=""
for entry in "${known_env[@]}"; do
  var="${entry%%:*}"; name="${entry#*:}"
  if [ -n "${!var:-}" ]; then found="$name"; marker="env $var"; break; fi
done

# Claude Squad runs plain tmux with no marker of its own: only its session name tells.
if [ "$found" = "tmux" ] && command -v tmux >/dev/null 2>&1; then
  case "$(tmux display -p '#S' 2>/dev/null)" in
    claudesquad_*) found="claude-squad"; marker="tmux session claudesquad_*" ;;
  esac
fi

# Process tree: /proc on Linux, ps elsewhere.
parent_of() {
  if [ -r "/proc/$1/stat" ]; then
    awk '{print $4}' "/proc/$1/stat" 2>/dev/null
  else
    ps -o ppid= -p "$1" 2>/dev/null | tr -d ' '
  fi
}
name_of() {
  if [ -r "/proc/$1/comm" ]; then cat "/proc/$1/comm" 2>/dev/null
  else ps -o comm= -p "$1" 2>/dev/null | sed 's#.*/##'
  fi
}

chain=(); pid=$$; hops=0
while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null && [ "$hops" -lt 40 ]; do
  n="$(name_of "$pid")"; [ -n "$n" ] && chain+=("$n")
  base="${n%%:*}"  # "tmux: server" -> "tmux"
  if [ -z "$found" ] && printf '%s' "$base" | grep -Eiq "^($known_proc)$"; then
    found="$(printf '%s' "$base" | tr 'A-Z' 'a-z' | sed 's/-gui$//; s/-server$//; s/^orca-ide$/orca/')"
    marker="process $n"
  fi
  pid="$(parent_of "$pid")"; hops=$((hops + 1))
done

candidates="$(env | cut -d= -f1 | grep -E '(PANE|(^|_)BLOCK(_|$)|WINDOW_ID|TERMINAL_ID|TERMINAL_HANDLE|SURFACE_ID|NODE_ID|THREAD_ID|MULTIPLEX|_SESSION(_ID)?$)' | sort -u | tr '\n' ' ')"

echo "multiplexer: ${found:-unknown}"
echo "marker: ${marker:-none}"
echo "candidates: ${candidates:-none}"
echo "ancestors: ${chain[*]:-unreadable (sandboxed?)}"

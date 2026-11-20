#!/usr/bin/env bash
# Detect the terminal multiplexer hosting this shell.
#
# Usage: bash assets/detect-multiplexer.sh
# Needs: bash, ps (or /proc on Linux). Prints plain text, never env values.
#
# Output:
#   multiplexer: <name>|unknown
#   marker: <env var or process that matched>
#   candidates: <env var names that look like pane/session IDs>
#   ancestors: <process chain from this shell up>

known_env=(
  "HERDR_ENV:herdr"
  "ORCA_TERMINAL_HANDLE:orca"
  "ORCA_PANE_KEY:orca"
  "REX_BLOCK:rex"
  "REX_SESSION:rex"
  "ZELLIJ:zellij"
  "TMUX:tmux"
  "WEZTERM_PANE:wezterm"
  "KITTY_WINDOW_ID:kitty"
  "STY:screen"
)
known_proc="herdr|orca|orca-ide|rex|zellij|tmux|wezterm|wezterm-gui|kitty|screen"

found=""; marker=""
for entry in "${known_env[@]}"; do
  var="${entry%%:*}"; name="${entry#*:}"
  if [ -n "${!var:-}" ]; then found="$name"; marker="env $var"; break; fi
done

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
    found="$(printf '%s' "$base" | tr 'A-Z' 'a-z' | sed 's/-gui$//; s/^orca-ide$/orca/')"
    marker="process $n"
  fi
  pid="$(parent_of "$pid")"; hops=$((hops + 1))
done

candidates="$(env | cut -d= -f1 | grep -E '(PANE|(^|_)BLOCK(_|$)|WINDOW_ID|TERMINAL_HANDLE|MULTIPLEX|_SESSION(_ID)?$)' | sort -u | tr '\n' ' ')"

echo "multiplexer: ${found:-unknown}"
echo "marker: ${marker:-none}"
echo "candidates: ${candidates:-none}"
echo "ancestors: ${chain[*]:-unreadable (sandboxed?)}"

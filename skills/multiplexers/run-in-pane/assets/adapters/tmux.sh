# Adapter for tmux. Contract: see ADAPTERS.md. Sourced by pane.sh, one function per call.
pane_available() { command -v tmux >/dev/null 2>&1; }
pane_marker() { [ -n "${TMUX:-}" ]; }
pane_locate() { # $1 = ancestor pids; print KEY=VALUE lines for the pane we run in
  local chain=" $1 " sock pid id
  for sock in "${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)"/*; do
    [ -S "$sock" ] || continue
    while read -r pid id; do
      case "$chain" in *" $pid "*) echo "TMUX=$sock,0,0"; echo "TMUX_PANE=$id"; return 0 ;; esac
    done < <(tmux -S "$sock" list-panes -a -F '#{pane_pid} #{pane_id}' 2>/dev/null)
  done
  return 1
}
pane_session() { tmux display-message -p '#{socket_path}:#{session_id}'; }
pane_open() { # title cwd dir(right|below) command...; print the new pane ID
  local title=$1 cwd=$2 dir=$3 flag=-h id cmd; shift 3
  [ "$dir" = below ] && flag=-v
  cmd=$(printf '%q ' "$@")
  id=$(tmux split-window -d -P -F '#{pane_id}' "$flag" -c "$cwd" "$cmd") || return 1
  tmux select-pane -t "$id" -T "$title"
  echo "$id"
}
pane_read() { tmux capture-pane -p -J -t "$1" -S "-$2"; }
pane_alive() { tmux list-panes -a -F '#{pane_id}' | grep -qx "$1"; }
pane_close() { tmux kill-pane -t "$1"; }

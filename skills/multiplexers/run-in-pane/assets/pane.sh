#!/usr/bin/env bash
# pane.sh: open, read, wait on and close panes, closing only panes this script opened.
#
# Usage:
#   pane.sh open --title TITLE [--cwd DIR] [--dir right|below] -- COMMAND [ARGS...]   prints the pane ID
#   pane.sh read ID [LINES]                  prints the last LINES (default 60) lines of the pane
#   pane.sh wait ID REGEX [SECONDS]          exit 0 when the output matches, 1 on timeout (default 60)
#   pane.sh close ID                         closes a pane from the ledger, refuses any other ID (exit 4)
#   pane.sh list                             prints the ledger IDs that are still alive
#
# Multiplexers: rex and tmux. Anything else exits 3: use that tool's own skill or --help.
# Ledger: one ID per line in $PANE_LEDGER, default $TMPDIR/pane-ledger-<mux>-<session>.
# A pane you did not open is never in the ledger, so close refuses it.
# Test hook: PANE_ADAPTER=/path/to/adapter.sh replaces the built-in multiplexer.
# Needs: bash, python3 (rex only: reads the JSON the create command prints).
set -u

die() { echo "pane.sh: $1" >&2; exit "${2:-1}"; }

# --- adapters: mux_session, mux_open TITLE CWD DIR CMD..., mux_read ID LINES, mux_alive ID, mux_close ID

rex_session() { echo "${REX_SESSION:-}"; }
rex_open() {
  local title=$1 cwd=$2 dir=$3; shift 3
  rex split -s "$REX_SESSION" ${REX_BLOCK:+-b "$REX_BLOCK"} --split="$dir" --focus=false \
    --label "$title" -c "$cwd" --json -- "$@" \
    | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["block_ids"][0])'
}
rex_read() { rex capture -s "$REX_SESSION" -b "$1" --trim | tail -n "$2"; }
rex_alive() { rex block ls -s "$REX_SESSION" --json | grep -q "\"block_id\": \"$1\""; }
rex_close() { rex block close -s "$REX_SESSION" "$1" >/dev/null; }

tmux_session() { tmux display-message -p '#{socket_path}:#{session_id}'; }
tmux_open() {
  local title=$1 cwd=$2 dir=$3 flag=-h id cmd; shift 3
  [ "$dir" = below ] && flag=-v
  cmd=$(printf '%q ' "$@")
  id=$(tmux split-window -d -P -F '#{pane_id}' "$flag" -c "$cwd" "$cmd") || return 1
  tmux select-pane -t "$id" -T "$title"
  echo "$id"
}
tmux_read() { tmux capture-pane -p -J -t "$1" -S "-$2"; }
tmux_alive() { tmux list-panes -a -F '#{pane_id}' | grep -qx "$1"; }
tmux_close() { tmux kill-pane -t "$1"; }

# --- pick the multiplexer

if [ -n "${PANE_ADAPTER:-}" ]; then
  # shellcheck disable=SC1090
  . "$PANE_ADAPTER"; mux=custom
else
  if [ -n "${REX_SESSION:-}" ] && command -v rex >/dev/null 2>&1; then mux=rex
  elif [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then mux=tmux
  else die "no supported multiplexer (rex, tmux) in this session: use the tool's own skill" 3
  fi
  for f in session open read alive close; do eval "mux_$f() { ${mux}_$f \"\$@\"; }"; done
fi

session=$(mux_session | tr -c 'A-Za-z0-9\n' '_')
ledger=${PANE_LEDGER:-${TMPDIR:-/tmp}/pane-ledger-$mux-$session}
touch "$ledger"
owned() { grep -qxF "$1" "$ledger"; }

cmd=${1:-}; [ $# -gt 0 ] && shift
case "$cmd" in
  open)
    title=; cwd=$PWD; dir=right
    while [ $# -gt 0 ]; do
      case "$1" in
        --title) title=${2:?--title needs a value}; shift 2 ;;
        --cwd) cwd=${2:?--cwd needs a value}; shift 2 ;;
        --dir) dir=${2:?--dir needs right or below}; shift 2 ;;
        --) shift; break ;;
        *) die "open: unknown option $1" 2 ;;
      esac
    done
    [ -n "$title" ] || die "open: --title is required" 2
    [ $# -gt 0 ] || die "open: a command is required after --" 2
    case "$dir" in right|below) ;; *) die "open: --dir is right or below" 2 ;; esac
    id=$(mux_open "$title" "$cwd" "$dir" "$@") || die "open failed"
    [ -n "$id" ] || die "open returned no pane ID"
    echo "$id" >> "$ledger"
    echo "$id"
    ;;
  read)
    id=${1:?read needs a pane ID}; mux_read "$id" "${2:-60}" ;;
  wait)
    id=${1:?wait needs a pane ID}; re=${2:?wait needs a REGEX}; secs=${3:-60}
    end=$(( $(date +%s) + secs ))
    while [ "$(date +%s)" -lt "$end" ]; do
      mux_read "$id" 200 2>/dev/null | grep -Eq "$re" && exit 0
      sleep 1
    done
    exit 1
    ;;
  close)
    id=${1:?close needs a pane ID}
    owned "$id" || die "refusing to close $id: this script did not open it" 4
    mux_close "$id" || die "close failed for $id"
    grep -vxF "$id" "$ledger" > "$ledger.tmp" || true; mv "$ledger.tmp" "$ledger"
    ;;
  list)
    while IFS= read -r id; do [ -n "$id" ] && mux_alive "$id" && echo "$id"; done < "$ledger"
    exit 0
    ;;
  *) die "usage: pane.sh open|read|wait|close|list (see the header)" 2 ;;
esac

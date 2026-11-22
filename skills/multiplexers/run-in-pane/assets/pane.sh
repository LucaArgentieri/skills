#!/usr/bin/env bash
# pane.sh: open, read, wait on and close panes, closing only panes this script opened.
#
# Usage:
#   pane.sh open --title TITLE [--cwd DIR] [--dir right|below] [--wait REGEX [--timeout SECS]] -- COMMAND [ARGS...]
#                                            prints the pane ID; with --wait, also the last output lines once
#                                            REGEX matches (exit 1 on timeout, the pane stays open and owned)
#   pane.sh read ID [LINES]                  prints the last LINES (default 60) lines of the pane
#   pane.sh wait ID REGEX [SECONDS]          exit 0 when the output matches, 1 on timeout (default 60)
#   pane.sh close ID|--all                   closes a pane from the ledger (--all: every one) and ends its process,
#                                            refuses any other ID (exit 4)
#   pane.sh list                             prints the ledger IDs that are still alive
#
# Multiplexers: rex, tmux and herdr. Anything else exits 3: use that tool's own skill or --help.
# It finds its own pane: REX_SESSION / TMUX / HERDR_PANE_ID when set, otherwise by matching its process
# ancestors to a pane's process, so an agent that strips environment variables still works.
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

herdr_session() { echo "${HERDR_SESSION:-herdr}-${HERDR_WORKSPACE_ID:-w}"; }
herdr_open() {
  local title=$1 cwd=$2 dir=$3 flag=right id; shift 3
  [ "$dir" = below ] && flag=down
  id=$(herdr pane split "$HERDR_PANE_ID" --direction "$flag" --cwd "$cwd" --no-focus \
    | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])') || return 1
  herdr pane rename "$id" "$title" >/dev/null
  herdr pane run "$id" "$(printf '%q ' "$@")" >/dev/null
  echo "$id"
}
herdr_read() { herdr pane read "$1" --source recent-unwrapped --lines "$2"; }
herdr_alive() { herdr pane list | grep -q "\"pane_id\":\"$1\""; }
herdr_close() { herdr pane close "$1" >/dev/null; }

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

# --- locate ourselves: match this process's ancestors to a pane's process

ancestors() { # prints "<pid> <pid> ..." from this shell up to init
  local p=$$ out=
  while [ -n "$p" ] && [ "$p" -gt 1 ] 2>/dev/null; do out="$out $p"; p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' '); done
  echo "$out"
}

# Each finder prints what to export when we run in one of its panes, and fails otherwise.

find_rex() {
  command -v rex >/dev/null 2>&1 || return 1
  ANCESTORS="$(ancestors)" python3 -I - <<'PY'
import json, os, subprocess, sys
chain = set(os.environ["ANCESTORS"].split())
def rex(*a):
    r = subprocess.run(["rex", *a], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""
try:
    sessions = [s["session_id"] for s in json.loads(rex("ls", "--json")).get("sessions", [])]
except ValueError:
    sys.exit(1)
for s in sessions:
    try:
        blocks = json.loads(rex("block", "ls", "-s", s, "--json")).get("blocks", [])
    except ValueError:
        continue
    for b in blocks:
        try:
            proc = json.loads(rex("block", "call", "-s", s, "-b", b["block_id"], "process"))
        except ValueError:
            continue
        if str((proc.get("child") or {}).get("pid")) in chain:
            print(s, b["block_id"]); sys.exit(0)
sys.exit(1)
PY
}

find_tmux() {
  command -v tmux >/dev/null 2>&1 || return 1
  local chain=" $(ancestors) " sock pid id
  for sock in "${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)"/*; do
    [ -S "$sock" ] || continue
    while read -r pid id; do
      case "$chain" in *" $pid "*) echo "$sock $id"; return 0 ;; esac
    done < <(tmux -S "$sock" list-panes -a -F '#{pane_pid} #{pane_id}' 2>/dev/null)
  done
  return 1
}

find_herdr() {
  command -v herdr >/dev/null 2>&1 || return 1
  ANCESTORS="$(ancestors)" python3 -I - <<'PY'
import json, os, subprocess, sys
chain = set(os.environ["ANCESTORS"].split())
def herdr(*a):
    r = subprocess.run(["herdr", *a], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""
try:
    panes = json.loads(herdr("pane", "list"))["result"]["panes"]
except (ValueError, KeyError):
    sys.exit(1)
for p in panes:
    try:
        info = json.loads(herdr("pane", "process-info", "--pane", p["pane_id"]))["result"]["process_info"]
    except (ValueError, KeyError):
        continue
    if any(str(fp.get("pid")) in chain for fp in info.get("foreground_processes", [])):
        print(p["pane_id"]); sys.exit(0)
sys.exit(1)
PY
}

locate() { # sets mux and exports its variables from the first multiplexer whose pane we run in
  local found
  if found=$(find_rex); then export REX_SESSION=${found% *} REX_BLOCK=${found#* }; mux=rex
  elif found=$(find_tmux); then export TMUX="${found% *},0,0" TMUX_PANE=${found#* }; mux=tmux
  elif found=$(find_herdr); then export HERDR_PANE_ID=$found; mux=herdr
  else return 1
  fi
}

# --- pick the multiplexer

if [ -n "${PANE_ADAPTER:-}" ]; then
  # shellcheck disable=SC1090
  . "$PANE_ADAPTER"; mux=custom
else
  if [ -n "${HERDR_PANE_ID:-}" ] && command -v herdr >/dev/null 2>&1; then mux=herdr
  elif [ -n "${REX_SESSION:-}" ] && command -v rex >/dev/null 2>&1; then mux=rex
  elif [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then mux=tmux
  elif locate; then :
  else die "not inside a rex, tmux or herdr pane (checked the environment and the process tree): use the tool's own skill" 3
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
    title=; cwd=$PWD; dir=right; waitre=; timeout=90
    while [ $# -gt 0 ]; do
      case "$1" in
        --title) title=${2:?--title needs a value}; shift 2 ;;
        --cwd) cwd=${2:?--cwd needs a value}; shift 2 ;;
        --dir) dir=${2:?--dir needs right or below}; shift 2 ;;
        --wait) waitre=${2:?--wait needs a REGEX}; shift 2 ;;
        --timeout) timeout=${2:?--timeout needs seconds}; shift 2 ;;
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
    if [ -n "$waitre" ]; then
      "$0" wait "$id" "$waitre" "$timeout" || die "open: no match for '$waitre' within ${timeout}s (pane $id stays open)"
      mux_read "$id" 20
    fi
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
    id=${1:?close needs a pane ID or --all}
    if [ "$id" = --all ]; then
      while IFS= read -r each; do [ -n "$each" ] && { "$0" close "$each" || exit 1; }; done < <(cat "$ledger")
      exit 0
    fi
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

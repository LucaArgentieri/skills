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
# The script knows no terminal tool by name. Each tool is an adapter file in adapters/ (ADAPTERS.md
# is the contract and how to write one), also read from $PANE_ADAPTER_DIR first. It picks the adapter
# whose marker says we run in one of its panes, else the one that finds our pane by matching our
# process ancestors to its panes (so an agent that strips environment variables still works).
# No adapter matches: exit 3, write one (ADAPTERS.md) or use the tool's own skill or --help.
# Ledger: one ID per line in $PANE_LEDGER, default $TMPDIR/pane-ledger-<adapter>-<session>.
# A pane you did not open is never in the ledger, so close refuses it.
# PANE_ADAPTER=/path/to/adapter.sh forces one adapter (tests, or a tool you choose by hand).
# Needs: bash, python3 (adapters may use it to read JSON).
set -u

die() { echo "pane.sh: $1" >&2; exit "${2:-1}"; }

here=$(cd "$(dirname "$0")" && pwd)

adapter_files() { # user adapters first, then the bundled ones
  local d f
  for d in ${PANE_ADAPTER_DIR:-} "$here/adapters"; do
    for f in "$d"/*.sh; do [ -f "$f" ] && echo "$f"; done
  done
}

try() { local f=$1; shift; ( . "$f"; "$@" ); } # run one adapter function in a subshell, so adapters never mix

ancestors() { # "<pid> <pid> ..." from this shell up to init
  local p=$$ out=
  while [ -n "$p" ] && [ "$p" -gt 1 ] 2>/dev/null; do out="$out $p"; p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' '); done
  echo "$out"
}

pick_adapter() { # sets adapter; exports what a locating adapter reports
  local f out line chain
  if [ -n "${PANE_ADAPTER:-}" ]; then adapter=$PANE_ADAPTER; return 0; fi
  while IFS= read -r f; do
    try "$f" pane_available >/dev/null 2>&1 && try "$f" pane_marker >/dev/null 2>&1 && { adapter=$f; return 0; }
  done < <(adapter_files)
  chain=$(ancestors)
  while IFS= read -r f; do
    try "$f" pane_available >/dev/null 2>&1 || continue
    out=$(try "$f" pane_locate "$chain" 2>/dev/null) || continue
    while IFS= read -r line; do
      case "$line" in [A-Za-z_]*=*) export "$line" ;; esac
    done <<< "$out"
    adapter=$f; return 0
  done < <(adapter_files)
  return 1
}

pick_adapter || die "not inside a pane of any known tool (adapters: $(adapter_files | xargs -n1 basename 2>/dev/null | sed 's/\.sh$//' | paste -sd, -); checked the environment and the process tree): write an adapter (ADAPTERS.md) or use the tool's own skill" 3
mux=$(basename "$adapter" .sh)
mux_session() { try "$adapter" pane_session; }
mux_open() { try "$adapter" pane_open "$@"; }
mux_read() { try "$adapter" pane_read "$@"; }
mux_alive() { try "$adapter" pane_alive "$@"; }
mux_close() { try "$adapter" pane_close "$@"; }

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

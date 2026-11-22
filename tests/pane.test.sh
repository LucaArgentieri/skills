#!/usr/bin/env bash
# Tests of pane.sh: the ownership ledger on a fake adapter, then the real rex and
# tmux adapters when those tools are available.
#
# Usage: bash tests/pane.test.sh
# Needs: bash, python3. rex and tmux cases skip (exit 0) when the tool is missing.
set -u
PANE="$(cd "$(dirname "$0")/.." && pwd)/skills/multiplexers/run-in-pane/assets/pane.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
pass=0; failn=0
ok()  { pass=$((pass + 1)); echo "ok   $1"; }
bad() { failn=$((failn + 1)); echo "FAIL $1"; }
check() { # name command...
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi
}
refused() { "$@" >/dev/null 2>&1; [ $? -eq 4 ]; }

# --- fake adapter: panes are files in $PANE_MOCK_DIR, "running" a command writes its output there
cat > "$work/mock.sh" <<'EOF'
mux_session() { echo mock; }
mux_open() { # title cwd dir cmd...
  local n; n=$(( $(ls "$PANE_MOCK_DIR" | wc -l) + 1 ))
  : > "$PANE_MOCK_DIR/m$n"
  ( cd "$2" && shift 3 && "$@" > "$PANE_MOCK_DIR/m$n" 2>&1 ) &
  echo "m$n"
}
mux_read() { tail -n "$2" "$PANE_MOCK_DIR/$1"; }
mux_alive() { [ -f "$PANE_MOCK_DIR/$1" ]; }
mux_close() { rm -f "$PANE_MOCK_DIR/$1"; }
EOF
export PANE_ADAPTER="$work/mock.sh" PANE_MOCK_DIR="$work/panes" PANE_LEDGER="$work/ledger"
mkdir "$PANE_MOCK_DIR"
: > "$PANE_MOCK_DIR/user-pane"   # a pane the user owns: never opened by pane.sh

id=$(bash "$PANE" open --title "web: dev" --cwd "$work" -- echo hello-from-pane)
[ "$id" = m2 ] && ok "open prints the pane ID" || bad "open prints the pane ID (got '$id')"
check "open records the ID in the ledger" grep -qx "$id" "$PANE_LEDGER"
check "wait sees the command output" bash "$PANE" wait "$id" 'hello-from-pane' 5
check "read returns the output" bash -c "bash '$PANE' read $id | grep -q hello-from-pane"
check "list shows the owned pane" bash -c "bash '$PANE' list | grep -qx $id"
check "close refuses a pane that was never opened here" refused bash "$PANE" close user-pane
check "the refused pane is still alive" test -f "$PANE_MOCK_DIR/user-pane"
check "close accepts an owned pane" bash "$PANE" close "$id"
check "the closed pane is gone" test ! -f "$PANE_MOCK_DIR/$id"
check "the ID leaves the ledger" bash -c "! grep -qx $id '$PANE_LEDGER'"
check "close refuses an ID twice" refused bash "$PANE" close "$id"
check "wait times out on no match" bash -c "! bash '$PANE' wait user-pane nomatch 2"
check "open without --title fails" bash -c "! bash '$PANE' open -- echo x"
check "open without a command fails" bash -c "! bash '$PANE' open --title t"
unset PANE_ADAPTER

# --- unsupported multiplexer exits 3
env -u REX_SESSION -u TMUX bash "$PANE" list >/dev/null 2>&1
[ $? -eq 3 ] && ok "no supported multiplexer exits 3" || bad "no supported multiplexer exits 3"

# --- real rex, in a throwaway session so no user pane is ever touched
if command -v rex >/dev/null 2>&1 && rex whoami >/dev/null 2>&1; then
  new=$(rex new "pane-test-$$" --json 2>/dev/null)
  sess=$(printf '%s' "$new" | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["session_id"])' 2>/dev/null)
  blk=$(printf '%s' "$new" | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["initial_windows"][0]["block_ids"][0])' 2>/dev/null)
  if [ -n "$sess" ] && [ -n "$blk" ]; then
    export REX_SESSION="$sess" REX_BLOCK="$blk" PANE_LEDGER="$work/rex-ledger"
    rid=$(bash "$PANE" open --title "test: rex" -- sh -c 'echo rex-ready; sleep 30')
    case "$rid" in block:*) ok "rex: open returns a block ID" ;; *) bad "rex: open returns a block ID (got '$rid')" ;; esac
    check "rex: wait sees the output" bash "$PANE" wait "$rid" 'rex-ready' 10
    check "rex: close refuses the user's own block" refused bash "$PANE" close "$blk"
    check "rex: close accepts the owned block" bash "$PANE" close "$rid"
    check "rex: the owned block is gone" bash -c "! bash '$PANE' list | grep -qx '$rid'"
    rex kill "$sess" >/dev/null 2>&1
    unset REX_SESSION REX_BLOCK
  else
    echo "skip: rex could not create a test session"
  fi
else
  echo "skip: rex not available"
fi

# --- real tmux, on a private server
if command -v tmux >/dev/null 2>&1; then
  export PANE_LEDGER="$work/tmux-ledger"
  tmux -L "pane-$$" new-session -d -s t -x 120 -y 40
  tsock=$(tmux -L "pane-$$" display-message -p '#{socket_path}')
  first=$(tmux -L "pane-$$" display-message -p -t t '#{pane_id}')
  T() { env TMUX="$tsock,1,0" TMUX_PANE="$first" bash "$PANE" "$@"; }
  tid=$(T open --title "test: tmux" -- sh -c 'echo tmux-ready; sleep 30')
  case "$tid" in %*) ok "tmux: open returns a pane ID" ;; *) bad "tmux: open returns a pane ID (got '$tid')" ;; esac
  check "tmux: wait sees the output" T wait "$tid" 'tmux-ready' 10
  check "tmux: close refuses the first pane" refused T close "$first"
  check "tmux: close accepts the owned pane" T close "$tid"
  tmux -L "pane-$$" kill-server 2>/dev/null
else
  echo "skip: tmux not installed"
fi

echo "pane: $pass passed, $failn failed"
[ "$failn" -eq 0 ]

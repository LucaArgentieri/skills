#!/usr/bin/env bash
# Test of pane.sh in herdr. Runs only inside a herdr pane (HERDR_ENV=1), otherwise skips
# (exit 0): CI has no herdr. Start it from a herdr pane: bash tests/herdr.test.sh
# Needs: bash, python3, herdr. Opens throwaway splits next to the pane it runs in and closes them.
set -u
if [ "${HERDR_ENV:-}" != 1 ] || ! command -v herdr >/dev/null 2>&1; then
  echo "skip: not inside a herdr pane"; exit 0
fi
PANE="$(cd "$(dirname "$0")/.." && pwd)/skills/multiplexers/run-in-pane/assets/pane.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export PANE_LEDGER="$work/ledger"
pass=0; failn=0
ok()  { pass=$((pass + 1)); echo "ok   $1"; }
bad() { failn=$((failn + 1)); echo "FAIL $1"; }
check() { local name=$1; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }
refused() { "$@" >/dev/null 2>&1; [ $? -eq 4 ]; }
alive() { herdr pane list | grep -q "\"pane_id\":\"$1\""; }

id=$(bash "$PANE" open --title "test: herdr" --cwd "$work" --wait 'herdr-ready' --timeout 15 -- sh -c 'echo herdr-ready; sleep 60' | head -n1)
case "$id" in w*:p*) ok "herdr: open --wait returns a pane ID" ;; *) bad "herdr: open --wait returns a pane ID (got '$id')" ;; esac
check "herdr: the pane exists" alive "$id"
check "herdr: read returns the output" bash -c "bash '$PANE' read $id | grep -q herdr-ready"
check "herdr: close refuses the pane running the test" refused bash "$PANE" close "$HERDR_PANE_ID"
check "herdr: close accepts the owned pane" bash "$PANE" close "$id"
check "herdr: the owned pane is gone" bash -c "! herdr pane list | grep -q '\"pane_id\":\"$id\"'"

# an agent that strips the environment: the script must find its own pane (the socket stays: it only says which herdr to ask)
sid=$(env -u REX_SESSION -u REX_BLOCK -u TMUX -u TMUX_PANE -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_BIN_PATH \
  bash "$PANE" open --title "test: stripped" --cwd "$work" -- sleep 60 | head -n1)
case "$sid" in w*:p*) ok "herdr: pane.sh finds its pane without HERDR_*" ;; *) bad "herdr: pane.sh finds its pane without HERDR_* (got '$sid')" ;; esac
[ -n "$sid" ] && check "herdr: the stripped-env pane is closable" bash "$PANE" close "$sid"

echo "herdr: $pass passed, $failn failed"
[ "$failn" -eq 0 ]

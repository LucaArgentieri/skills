# Adapter for herdr. Contract: see ADAPTERS.md. Sourced by pane.sh, one function per call.
pane_available() { command -v herdr >/dev/null 2>&1; }
pane_marker() { [ -n "${HERDR_PANE_ID:-}" ]; }
pane_locate() { # $1 = ancestor pids; print KEY=VALUE lines for the pane we run in
  local found
  found=$(ANCESTORS="$1" python3 -I - <<'PY'
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
  ) || return 1
  echo "HERDR_PANE_ID=$found"
}
pane_session() { echo "${HERDR_SESSION:-herdr}-${HERDR_WORKSPACE_ID:-w}"; }
pane_open() { # title cwd dir(right|below) command...; print the new pane ID
  local title=$1 cwd=$2 dir=$3 flag=right id; shift 3
  [ "$dir" = below ] && flag=down
  id=$(herdr pane split "$HERDR_PANE_ID" --direction "$flag" --cwd "$cwd" --no-focus \
    | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])') || return 1
  herdr pane rename "$id" "$title" >/dev/null
  herdr pane run "$id" "$(printf '%q ' "$@")" >/dev/null
  echo "$id"
}
pane_read() { herdr pane read "$1" --source recent-unwrapped --lines "$2"; }
pane_alive() { herdr pane list | grep -q "\"pane_id\":\"$1\""; }
pane_close() { herdr pane close "$1" >/dev/null; }

# Adapter for rex. Contract: see ADAPTERS.md. Sourced by pane.sh, one function per call.
pane_available() { command -v rex >/dev/null 2>&1; }
pane_marker() { [ -n "${REX_SESSION:-}" ]; }
pane_locate() { # $1 = ancestor pids; print KEY=VALUE lines for the pane we run in
  local found
  found=$(ANCESTORS="$1" python3 -I - <<'PY'
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
  ) || return 1
  echo "REX_SESSION=${found% *}"; echo "REX_BLOCK=${found#* }"
}
pane_session() { echo "${REX_SESSION:-}"; }
pane_open() { # title cwd dir(right|below) command...; print the new pane ID
  local title=$1 cwd=$2 dir=$3; shift 3
  rex split -s "$REX_SESSION" ${REX_BLOCK:+-b "$REX_BLOCK"} --split="$dir" --focus=false \
    --label "$title" -c "$cwd" --json -- "$@" \
    | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["block_ids"][0])'
}
pane_read() { rex capture -s "$REX_SESSION" -b "$1" --trim | tail -n "$2"; }
pane_alive() { rex block ls -s "$REX_SESSION" --json | grep -q "\"block_id\": \"$1\""; }
pane_close() { rex block close -s "$REX_SESSION" "$1" >/dev/null; }

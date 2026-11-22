#!/usr/bin/env bash
# End-to-end test of the pane flows of delegate-to-pane and run-in-pane on a
# real tmux server, with a fake agent standing in for claude/codex/opencode.
#
# Usage: bash tests/tmux-e2e.test.sh
# Needs: bash, tmux, python3, curl. Skips (exit 0) without tmux.
set -u
command -v tmux >/dev/null 2>&1 || { echo "skip: tmux not installed"; exit 0; }

SOCK="e2e-$$"
T() { tmux -L "$SOCK" "$@"; }
work="$(mktemp -d)"
trap 'T kill-server 2>/dev/null; rm -rf "$work"' EXIT
pass=0; failn=0
ok()  { pass=$((pass + 1)); echo "ok   $1"; }
bad() { failn=$((failn + 1)); echo "FAIL $1"; }
wait_for() { # pane pattern seconds
  for _ in $(seq $(($3 * 5))); do
    T capture-pane -p -J -t "$1" -S -200 | grep -Eq "$2" && return 0; sleep 0.2
  done; return 1
}
pane_exists() { T list-panes -a -F '#{pane_id}' | grep -qx "$1"; }

# Fake agent: reads a brief, does "TASK: write <text> to <file>", replies with STATUS.
cat > "$work/fake-agent.sh" <<'EOF'
#!/usr/bin/env bash
echo "fake-agent ready"
brief=""
while IFS= read -r line; do
  [ "$line" = "/exit" ] && exit 0
  brief+="$line"$'\n'
  while IFS= read -r -t 0.5 more; do brief+="$more"$'\n'; done
  task="$(printf '%s' "$brief" | sed -n 's/^TASK: write \(.*\) to \(.*\)$/\1|\2/p')"
  if [ -n "$task" ]; then
    printf '%s\n' "${task%%|*}" > "${task#*|}"
    echo "wrote ${task#*|}"
    echo "STATUS: DONE"
  else
    echo "STATUS: BLOCKED no TASK line"
  fi
  brief=""
done
EOF

# The parent agent's own pane.
T new-session -d -s work -x 220 -y 50 -c "$work"
parent="$(T display -p -t work '#{pane_id}')"

echo "# delegate-to-pane"
child="$(T split-window -h -d -t "$parent" -c "$work" -P -F '#{pane_id}' "bash '$work/fake-agent.sh'")"
[ -n "$child" ] && pane_exists "$child" && ok "split a pane beside the parent" || bad "split a pane"
[ "$(T display -p -t "$parent" '#{pane_active}')" = 1 ] && ok "focus stays on the parent" || bad "focus moved"
wait_for "$child" "fake-agent ready" 5 && ok "agent ready" || bad "agent never ready"

T select-pane -t "$child" -T "codex"
[ "$(T display -p -t "$child" '#{pane_title}')" = "codex" ] && ok "pane titled with the agent name" || bad "pane title"

brief="CLASS: execution
TASK: write hello-from-subagent to $work/result.txt
DONE WHEN: $work/result.txt contains hello-from-subagent
RETURN: the file path
RULES:
- End every reply with one line: STATUS: DONE or STATUS: BLOCKED <reason>."
printf '%s' "$brief" | T load-buffer -b brief -
T paste-buffer -p -d -b brief -t "$child"
T send-keys -t "$child" Enter
wait_for "$child" "^STATUS: DONE" 10 && ok "reply ends with STATUS: DONE" || bad "no STATUS line"

# Close gate: verify with evidence, not the claim.
[ "$(cat "$work/result.txt" 2>/dev/null)" = "hello-from-subagent" ] && ok "close gate: file verified" || bad "close gate: file missing"

# Kill: exit command, close, verify gone.
T send-keys -t "$child" "/exit" Enter
sleep 0.5
pane_exists "$child" && T kill-pane -t "$child"
pane_exists "$child" && bad "pane still listed after kill" || ok "pane gone from the pane list"

echo "# run-in-pane"
port=$((20000 + RANDOM % 20000))
cmd="python3 -m http.server $port --bind 127.0.0.1"
srv="$(T split-window -h -d -t "$parent" -c "$work" -P -F '#{pane_id}' "$cmd")"
T select-pane -t "$srv" -T "web: dev"
[ "$(T display -p -t "$srv" '#{pane_title}')" = "web: dev" ] && ok "process pane titled <project>: <process>" || bad "process pane title"
wait_for "$srv" "Serving HTTP" 10 && ok "process ready" || bad "process never ready"
curl -fs "http://127.0.0.1:$port/" >/dev/null && ok "dev server answers" || bad "dev server unreachable"

# Reuse: exactly one pane runs this command.
count="$(T list-panes -a -F '#{pane_start_command}' | grep -c "http.server $port")"
[ "$count" = 1 ] && ok "one pane per process" || bad "found $count panes running the server"

T send-keys -t "$srv" C-c
sleep 0.5
pane_exists "$srv" && T kill-pane -t "$srv"
pane_exists "$srv" && bad "process pane still listed" || ok "helper pane stopped and gone"
[ "$(T list-panes -a | wc -l | tr -d ' ')" = 1 ] && ok "only the parent pane is left" || bad "stray panes left"

echo "tmux-e2e: $pass passed, $failn failed"
[ "$failn" -eq 0 ]

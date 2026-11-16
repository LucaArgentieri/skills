# tmux backend

Read when `$TMUX` is set. tmux knows nothing about agents, so readiness and completion come from reading the pane.

## Spawn

Split next to your own pane (`$TMUX_PANE`), keeping your cwd and focus, and print the new pane ID:

```bash
tmux split-window -h -d -t "$TMUX_PANE" -c "$PWD" -P -F '#{pane_id}'
```

Use `-v` instead of `-h` when your pane is narrow (`tmux display -p -t "$TMUX_PANE" '#{pane_width}x#{pane_height}'`). Name it so the user can see it:

```bash
tmux select-pane -t <pane-id> -T <name>
```

Start the agent with its own CLI (`claude`, `codex`, `opencode`, ...):

```bash
tmux send-keys -t <pane-id> '<agent-command>' Enter
```

Ready when its input prompt shows in a capture (below).

## Send and wait

Paste the brief through a buffer so newlines do not submit early, then press Enter:

```bash
printf '%s' "<brief>" | tmux load-buffer -b brief -
tmux paste-buffer -p -d -b brief -t <pane-id>
tmux send-keys -t <pane-id> Enter
```

Some agents need a second `Enter` after a large paste. Check a capture before sending it.

Wait by polling the capture every 15 to 30 seconds until a `STATUS:` line or a permission prompt appears:

```bash
tmux capture-pane -p -J -t <pane-id> -S -200 | grep -E '^STATUS:'
```

## Read

```bash
tmux capture-pane -p -J -t <pane-id> -S -200
```

## Close

Exit the agent with its own quit command or `C-c`, then:

```bash
tmux kill-pane -t <pane-id>
```

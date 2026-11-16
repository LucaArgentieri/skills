# herdr backend

Read when `HERDR_ENV=1`. The installed `herdr` CLI is the authority: when a flag below fails, check `herdr <group>` (for example `herdr pane`) for the current syntax. Never run bare `herdr`, it opens the TUI.

Commands return JSON. Read IDs from the responses: `$HERDR_PANE_ID` is your own pane.

## Spawn

Pick the split direction from your pane's shape:

```bash
herdr pane layout --pane "$HERDR_PANE_ID"
```

Split, keeping your cwd and your focus:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
```

Use `down` for a narrow or tall pane. The new pane ID is `.result.pane.pane_id`.

Start the agent in it. `herdr agent` lists the supported kinds, and `herdr agent list` shows which kind you are:

```bash
herdr agent start <name> --kind <kind> --pane <pane-id>
```

It returns once the agent is ready. On `agent_not_ready` the agent is blocked at startup: read it (below) and apply hard rule 4.

## Send and wait

```bash
herdr agent prompt <name> "<brief>" --wait --timeout 600000
```

`--wait` returns at the first `idle`, `done` or `blocked` state. Raise the timeout for long tasks. A timeout or `agent_prompt_stalled` does not prove the prompt was lost: read before re-sending.

Wait again without sending anything:

```bash
herdr agent wait <name> --timeout 600000
```

## Read

```bash
herdr agent get <name>                                     # state
herdr agent read <name> --source recent-unwrapped --lines 200
```

`blocked` means a permission or question prompt is on screen.

## Close

```bash
herdr pane close <pane-id>
```

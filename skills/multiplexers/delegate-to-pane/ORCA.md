# Orca backend

Read when `ORCA_TERMINAL_HANDLE` is set (`test -n "${ORCA_TERMINAL_HANDLE:-}"`). Orca sets it in every terminal it manages, and it is your own pane's handle.

The CLI is `$ORCA_CLI_COMMAND` when that is set, otherwise `orca`. Below, `orca` means that executable. When a flag fails, `orca terminal --help` or `orca skills get orca-cli` has the current syntax.

Add `--json` to every command and read handles from the responses.

This backend uses plain Orca terminals. When the user asks for Orca workers, supervision, task DAGs or a separate worktree, use Orca's own `orchestration` skill instead.

## Spawn

Split your own terminal and start the agent in the new pane:

```bash
orca terminal split --terminal "$ORCA_TERMINAL_HANDLE" --direction vertical \
  --command "<agent-command>" --json
```

`vertical` splits left/right, `horizontal` top/bottom. The new handle is `result.split.handle`. Title it so the user can see it:

```bash
orca terminal set-pane-title --terminal <handle> --title "<name>" --json
```

Wait until the agent is ready:

```bash
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
```

## Send and wait

```bash
orca terminal send --terminal <handle> --text "<brief>" --enter --wait-submit 10 --json
```

`accepted: true` means the input arrived; the `turn_started` stage proves the turn began. On silence, read before re-sending. `agent_prompt_blocked` means a permission or trust menu is on screen: apply hard rule 4, and answer the menu by sending `--text` and `--enter` as separate commands.

Wait for the turn to end:

```bash
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 600000 --json
```

## Read

```bash
orca terminal read --terminal <handle> --screen --json
```

`--screen` returns what the pane shows now. Plain `read` returns stacked fragments for TUIs, so long replies come through the result file from the brief.

## Close

```bash
orca terminal close --terminal <handle> --json
```

Close by handle only. `terminal close --all` and `terminal switch` act on the user's terminals too.

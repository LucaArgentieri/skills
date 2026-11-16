# rex backend

Read when `REX_BLOCK` is set (`test -n "${REX_BLOCK:-}"`). rex sets it, with `REX_SESSION`, in every terminal it opens. `REX_BLOCK` is your own pane (rex calls panes **blocks**). When a flag below fails, `rex help <command>` has the current syntax.

rex has no agent states, so readiness and completion come from reading the block.

## Spawn

Split next to your own block, keeping your cwd and focus, and start the agent in the new block:

```bash
rex split -b "$REX_BLOCK" --split right --cwd "$PWD" --focus=false \
  --label <name> --interactive --json -- <agent-command> | jq -r '.block_ids[0]'
```

Use `--split below` for a narrow pane. `--interactive` loads the shell config, so agent CLIs installed there are on `PATH`. Anchor with `-b "$REX_BLOCK"` always: without it rex splits the focused block, which may be the user's.

Ready when the agent's input prompt shows in a capture (below).

## Send and wait

`rex send` types text without pressing Enter, and a newline in the text may submit early. So write the brief to a file and send one line:

```bash
printf '%s\n' "<brief>" > <tmp-dir>/<name>-brief.md
rex send -b <block-id> 'Read <tmp-dir>/<name>-brief.md and follow it.'
rex send-key -b <block-id> enter
```

Send follow-ups the same way, one line or one file.

`rex wait` returns only when the agent process exits, so it cannot tell when a turn ends. Poll the capture every 15 to 30 seconds until a `STATUS:` line or a permission prompt appears:

```bash
rex capture -b <block-id> --trim --unwrap | tail -n 200 | grep -E '^STATUS:'
```

## Read

```bash
rex capture -b <block-id> --trim --unwrap | tail -n 200
```

## Close

Exit the agent with its own quit command or `rex send-key -b <block-id> ctrl+c`, then:

```bash
rex block close <block-id>
```

Leave `rex server stop` and `rex kill` alone: they end the user's other programs too.

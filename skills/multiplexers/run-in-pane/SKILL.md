---
name: run-in-pane
description: Start dev servers, watchers, tunnels and other commands that keep running in their own visible, titled terminal pane the user can watch and stop, instead of in the background. Use when the user asks you to start a process that keeps running (`bun run dev`, `npm run dev`, `--watch`, `serve`, `docker compose up`, `tail -f`), or to show a build, test or script in a visible pane. Otherwise not for commands that finish on their own. For handing a task to another agent use delegate.
---

# Run in a pane

A process that keeps running gets its own **visible** pane, titled with what it is, so the user can watch its output and stop it. Builds, tests and scripts that finish stay in your own shell.

This skill covers processes. Handing a task to another agent is a different job: the `delegate` skill.

## Hard rules

1. **Visible, never hidden.** Inside a multiplexer, start long-running processes in a pane. `&`, `nohup`, `disown`, `setsid` and your agent's background-run option hide them from the user.
2. **One pane per process.** Reuse a pane that already runs the same command in the same folder. A second dev server only fights the first for the port.
3. **Your panes only, by ID.** Record the pane ID the create command returns, and close only recorded IDs. A pane you reused, or found by label or position, is not yours: leave it running.

## Steps

### 1. Find the multiplexer

Run `bash assets/pane.sh list`. It finds its own pane by itself, even when the environment variables are stripped, through the adapter of the tool you run in (`ls assets/adapters`), and keeps a ledger of the panes it opened: with it, steps 2, 3 and 5 are one command each, `pane.sh` covers steps 2, 3 and 5; the tool's own skill is needed only to write an adapter.

Exit code 3 means no adapter knows this tool: write one by following [ADAPTERS.md](ADAPTERS.md) (the tool's own skill or `--help` gives the commands), save it in `$PANE_ADAPTER_DIR` or `assets/adapters/`, and run `pane.sh` again. With no multiplexer at all, or at level `agent`, there is no terminal you can open: run the process with your agent's background option and tell the user the command and where its output goes.

**Done when** `pane.sh list` runs, or the user knows the process runs in the background and why.

### 2. Reuse or spawn

List the panes. When one already runs the same command in the same folder, use it and stop here: it stays the user's.

Otherwise open a new pane beside yours (or a new terminal, at level `tab`), in the project folder, leaving focus on your pane. Title it `<project>: <process>`: `web: dev`, `cms: studio`, `api: docker`. Run the command in it as a plain foreground command:

```bash
bash assets/pane.sh open --title "web: dev" --cwd "$PWD" --wait "ready|localhost" --timeout 90 -- bun run dev
```

It prints the pane ID, then the last output lines once the process is ready.

**Done when** exactly one pane runs the process, it shows its title, and you hold its ID (or it is a reused pane).

### 3. Wait until ready

`--wait` covers it: the pattern is what the process prints when ready (a URL, a port, "ready", "compiled"). On a timeout or an error line, read the pane (`bash assets/pane.sh read <id>`), fix the cause, then close that recorded pane with `pane.sh close <id>` before opening again: one pane per process.

**Done when** the process is ready, and you have its URL or port.

### 4. Tell the user

One line, in their language: what runs, in which pane, and its URL.

**Done when** the user knows where the process is.

### 5. When the work ends

- **Dev servers and studios** stay up: the user will want to look at the result. List them in your final summary.
- **Helpers** you started only for your own check (a watcher for one test, a tunnel, a log tail) get stopped and closed as soon as you no longer need them: `bash assets/pane.sh close <id>` (or `close --all` for every pane you opened) ends the process with its pane, so send no keys first.

Stop a dev server earlier only when the user asks, or when it blocks something (a port, a rebuild).

**Done when** every pane you created is either listed in your summary or closed.

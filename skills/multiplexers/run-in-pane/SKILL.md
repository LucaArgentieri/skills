---
name: run-in-pane
description: Run every long-running process (dev server, Sanity Studio, watcher, tunnel, log tail, docker compose up) in its own visible, titled pane of the current terminal multiplexer instead of in the background. Use before starting any command that keeps running ("npm run dev", "sanity dev", "--watch", "serve", "up", "tail -f"), whether you are the main agent or a subagent. For handing a task to another agent use delegate-to-pane.
---

# Run in a pane

A process that keeps running gets its own **visible** pane, titled with what it is, so the user can watch its output and stop it. Builds, tests and scripts that finish stay in your own shell.

This skill covers processes. Other agents in panes are the job of the `delegate-to-pane` skill.

## Hard rules

1. **Visible, never hidden.** Inside a multiplexer, start long-running processes in a pane. `&`, `nohup`, `disown`, `setsid` and your agent's background-run option hide them from the user.
2. **One pane per process.** Reuse a pane that already runs the same command in the same folder. A second dev server only fights the first for the port.
3. **Your panes only, by ID.** Record the pane ID the create command returns, and close only recorded IDs. A pane you reused, or found by label or position, is not yours: leave it running.

## Steps

### 1. Find the multiplexer

When the multiplexer is already known (the session context names it, or its list command answers), skip detection and use that tool's own skill or `--help`. Otherwise use step 1 of the `delegate-to-pane` skill: it detects the multiplexer, its commands and its level.

Here you need: open a pane beside yours (level `split`) or a new terminal in the same workspace (level `tab`) with a working directory, run a command in it, set its title, read its output, list them, and close one.

At level `agent` or `none`, or with no multiplexer, the tool has no terminal you can open: run the process with your agent's background option and tell the user the command and where its output goes.

**Done when** you have those commands, or the user knows the process runs in the background and why.

### 2. Reuse or spawn

List the panes. When one already runs the same command in the same folder, use it and stop here: it stays the user's.

Otherwise open a new pane beside yours (or a new terminal, at level `tab`), in the project folder, leaving focus on your pane where the multiplexer allows it. Title it `<project>: <process>`: `web: dev`, `sanity: studio`, `api: docker`. Run the command in it as a plain foreground command. Record the returned pane ID.

**Done when** exactly one pane runs the process, it shows its title, and you hold its ID (or it is a reused pane).

### 3. Wait until ready

Read the pane until the process says it is ready (a URL, a port, "ready", "compiled") or fails. On failure, read the error from the pane and fix it there.

**Done when** the process is ready, and you have its URL or port.

### 4. Tell the user

One line, in their language: what runs, in which pane, and its URL.

**Done when** the user knows where the process is.

### 5. When the work ends

- **Dev servers and studios** stay up: the user will want to look at the result. List them in your final summary.
- **Helpers** you started only for your own check (a watcher for one test, a tunnel, a log tail) get stopped (`Ctrl-C`) and their pane closed by its recorded ID as soon as you no longer need them.

Stop a dev server earlier only when the user asks, or when it blocks something (a port, a rebuild).

**Done when** every pane you created is either listed in your summary or closed.

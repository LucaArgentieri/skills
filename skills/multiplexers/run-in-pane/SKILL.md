---
name: run-in-pane
description: Run every long-running process (dev server, Sanity Studio, watcher, tunnel, log tail, docker compose up) in its own visible, titled pane of the current terminal multiplexer instead of in the background. Use before starting any command that keeps running ("npm run dev", "sanity dev", "--watch", "serve", "up", "tail -f"), whether you are the main agent or a subagent. For handing a task to another agent use delegate-to-pane.
---

# Run in a pane

Panes are how the user keeps everything under control and sees what agents actually do. A process that keeps running gets its own **visible** pane, titled with what it is, so the user can watch its output and stop it.

This skill covers processes. Other agents in panes are the job of the `delegate-to-pane` skill.

## Hard rules

1. **Visible, never hidden.** Inside a multiplexer, start long-running processes in a pane. `&`, `nohup`, `disown`, `setsid` and your agent's background-run option hide them from the user.
2. **One pane per process.** Reuse a pane that already runs the same command in the same folder. A second dev server only fights the first for the port.
3. **Your panes only.** Stop and close panes you opened. Leave the user's alone.

## What counts as long-running

A command that does not exit on its own: dev servers (`npm run dev`, `vite`, `next dev`, `astro dev`), studios (`sanity dev`), watchers (`--watch`, `tsc -w`), local servers (`serve`, `python -m http.server`), `docker compose up`, tunnels, `tail -f`.

Builds, tests and scripts that finish stay in your own shell.

## Steps

### 1. Find the multiplexer

Use step 1 of the `delegate-to-pane` skill: it detects the multiplexer and its commands. Here you need: split a pane beside yours with a working directory, run a command in it, set its title, read its output, list panes, and close a pane.

When there is no multiplexer, run the process with your agent's background option and tell the user the command and where its output goes.

**Done when** you have those commands, or the user knows the process runs in the background and why.

### 2. Reuse or spawn

List the panes. When one already runs the same command in the same folder, use it and stop here.

Otherwise open a new pane beside yours, in the project folder, leaving focus on your pane where the multiplexer allows it. Title it `<project> · <process>`: `web · dev`, `sanity · studio`, `api · docker`. Run the command in it as a plain foreground command.

**Done when** exactly one pane runs the process, and it shows its title.

### 3. Wait until ready

Read the pane until the process says it is ready (a URL, a port, "ready", "compiled") or fails. On failure, read the error from the pane and fix it there.

**Done when** the process is ready, and you have its URL or port.

### 4. Tell the user

One line, in their language: what runs, in which pane, and its URL.

**Done when** the user knows where the process is.

### 5. When the work ends

- **Dev servers and studios** stay up: the user will want to look at the result. List them in your final summary.
- **Helpers** you started only for your own check (a watcher for one test, a tunnel, a log tail) get stopped (`Ctrl-C`) and their pane closed as soon as you no longer need them.

Stop a dev server earlier only when the user asks, or when it blocks something (a port, a rebuild).

**Done when** every pane you opened is either listed in your summary or closed.

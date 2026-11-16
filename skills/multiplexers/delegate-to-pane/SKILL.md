---
name: delegate-to-pane
description: Run a subagent as a visible agent in a new pane of the current multiplexer workspace (herdr, Orca, rex, tmux), briefed in English and kept open until its subtask is verified complete. Use when the user asks to hand a task to a subagent ("fai fare a un subagent", "delega"), to run agents in parallel, or to spawn another agent, while you run inside a multiplexer.
---

# Delegate to a pane

Every subagent lives in its own **pane** next to yours, in the workspace you are running in, so the user can watch it and step in. You brief it, wait for it, verify its work, and close the pane only when the subtask is truly done.

This skill decides *how* a subagent is run and closed. The multiplexer commands live in one file per backend.

## Hard rules

1. **English only with the subagent.** The brief, follow-ups and answers you relay are in English, because it costs fewer tokens. Talk to the user in their language.
2. **Close gate.** A pane closes only when step 5 passes. A subagent that says "done" is a claim, not proof.
3. **Your panes only.** Close panes you created. Leave every other pane alone.
4. **Approvals belong to the user.** When the subagent waits at an approval or permission prompt, show it to the user and relay their answer. Never answer it yourself.

## Steps

### 1. Detect the backend

Check in this order and read the matching file:

| Check | Backend | Read |
| --- | --- | --- |
| `test "${HERDR_ENV:-}" = 1` | herdr | [HERDR.md](HERDR.md) |
| `test -n "${ORCA_TERMINAL_HANDLE:-}"` | Orca | [ORCA.md](ORCA.md) |
| `test -n "${REX_BLOCK:-}"` | rex | [REX.md](REX.md) |
| `test -n "${TMUX:-}"` | tmux | [TMUX.md](TMUX.md) |

When none matches, tell the user in one line that no multiplexer was found and run the subtask with your agent's own subagent mechanism, or inline if it has none. The brief and the close gate still apply.

**Done when** one backend is chosen and its file is read, or the fallback is announced.

### 2. Write the brief

The subagent shares none of your memory. Fill this template, in English, terse but complete:

```
TASK: <one sentence>
CONTEXT: <paths, decisions, constraints, anything it cannot discover alone>
DONE WHEN: <checkable criteria, one per line>
RETURN: <exactly what to report back>
RULES:
- Reply in English only, as briefly as possible. If an output-compression skill is available (for example caveman), use it for every reply.
- Stay inside TASK. Commit, push or delete only if TASK says so.
- If a decision belongs to the user, stop and ask it in your reply.
- If the result is longer than about 40 lines, write it to <tmp-dir>/<name>-result.md and reply with the path.
- End every reply with one line: `STATUS: DONE` or `STATUS: BLOCKED <reason>`.
```

Pick a short role **name** (`reviewer`, `test-fixer`), unique among live agents.

**Done when** every field is filled and DONE WHEN is checkable by you, from files, commands or output.

### 3. Spawn the pane

Follow the backend file. Defaults, unless the user said otherwise:

- A sibling pane in the current tab, split right from a wide pane and down from a tall one.
- The same working directory as yours.
- Focus stays on your pane.
- The agent kind the user named, otherwise the same kind as you.

**Done when** the agent is running and ready for input in the new pane, and you have recorded its pane ID.

### 4. Send the brief and wait

Send the brief as one prompt and wait until the agent settles (idle, done or blocked) or a `STATUS:` line appears. Then read its latest output, or the result file it points to.

**Done when** you have its reply ending in a `STATUS:` line, or it is blocked on a prompt.

### 5. Close gate

Check the reply against the brief:

- every DONE WHEN criterion verified by you, with evidence (run the test, open the file, read the diff)
- every RETURN item present
- nothing left you still need to ask it

On a gap, send a follow-up in English in the **same pane** and go back to step 4. On `STATUS: BLOCKED` with a question for the user, ask the user and relay the answer. When the backend shows a permission prompt, apply hard rule 4.

**Done when** all three checks pass.

### 6. Close and report

Close the pane (backend file), then report to the user in their language: what the subagent did, what you verified, where the results are.

Keep the pane open instead when the user asked to keep it, and say so.

**Done when** the pane is closed (or kept on request) and the user has the summary.

## Several subagents

One pane and one brief per subagent, all spawned before waiting on any. Run steps 4 and 5 for each one separately, and close each pane as soon as its own gate passes.

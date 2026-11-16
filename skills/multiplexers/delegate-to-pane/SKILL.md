---
name: delegate-to-pane
description: Decide how a subagent is run when you delegate from inside any terminal multiplexer (herdr, Orca, rex, tmux, ...) - its own visible pane in your workspace, an English brief, the cheapest model that fits, and a close gate on verified completion. Use when the user asks to hand a task to a subagent ("fai fare a un subagent", "delega"), to run agents in parallel, or to spawn another agent.
---

# Delegate to a pane

A delegation policy. It decides where a subagent runs, how it is briefed, which model it gets, and when it may close.

It works with any multiplexer. The pane commands belong to the multiplexer: learn them from its own skill or CLI help, and keep its rules as they are.

## Find the multiplexer

1. **Its skill.** Many multiplexers ship a skill for agents. If one among your skills controls the terminal you run in, use it.
2. **Environment.** Multiplexers mark their panes with variables, usually a session or pane ID. List them with `env | cut -d= -f1 | sort` and look for a tool prefix.
3. **Process tree.** Walk up from your shell to see what hosts it:

   ```bash
   pid=$$; while [ "${pid:-1}" -gt 1 ]; do ps -o comm= -p "$pid"; pid=$(ps -o ppid= -p "$pid" | tr -d ' '); done
   ```

Known today, as examples:

| Marker | Multiplexer | Commands from |
| --- | --- | --- |
| `HERDR_ENV=1` | herdr | its `herdr` skill, or `herdr --help` |
| `ORCA_TERMINAL_HANDLE` | Orca | `orca skills get orca-cli` |
| `REX_BLOCK` | rex | its agent skill, or `rex help` |
| `TMUX` | tmux | `man tmux` |

For one you don't know, read `<tool> --help` (or `<tool> help`) and its docs. A bare `<tool>` with no arguments often opens its UI, so always pass a help flag.

From the skill or the help, find a command for each **capability**:

- split a new pane beside a given pane, with a working directory
- run a command in it
- send text and Enter to it
- read its output
- wait for it to go idle, or poll the output
- close it by ID
- your own pane's ID (usually an environment variable)

**Done when** you have a command for every capability. If one is missing, or no multiplexer is found, tell the user in one line and use your agent's own subagent mechanism, or work inline. The brief, model choice and close gate still apply.

## Hard rules

1. **English only with the subagent.** The brief, follow-ups and relayed answers are in English, because it costs fewer tokens. Talk to the user in their language.
2. **Close gate.** A pane closes only when step 6 passes. A subagent that says "done" is a claim, not proof.
3. **Your panes only.** Close panes you created. Leave every other pane alone.
4. **Approvals belong to the user.** When the subagent waits at a permission or approval prompt, show it to the user and relay their answer.

## Steps

### 1. Classify the task

- **execution**: you already did the thinking. The plan names the files, the changes and the commands, and no design choice is left. Running it is mechanical.
- **reasoning**: the subagent must investigate, design, judge or choose.

When in doubt, it is reasoning.

**Done when** the task has one class, and you can say why in one line.

### 2. Pick the model

- **reasoning**: the same model as yours.
- **execution**: a lower tier of the same family. Thinking already happened, so a faster, cheaper model runs it as well. For example:

| You run on | Execution subagent |
| --- | --- |
| Fable, Opus | Sonnet 5.5, or Haiku 5.5 for trivial steps |
| Astra | Sol, or Luna for trivial steps |

For other families apply the same idea: one tier down, two for trivial steps. Pass the model with the agent CLI's own model option. When the user named a model or agent, theirs wins.

**Done when** the agent kind and model are chosen.

### 3. Write the brief

The subagent shares none of your memory. Fill this template in English, terse but complete:

```
CLASS: <execution | reasoning>
TASK: <one sentence>
CONTEXT: <paths, decisions, constraints, anything it cannot discover alone>
PLAN: <execution only: the exact steps, in order>
DONE WHEN: <checkable criteria, one per line>
RETURN: <exactly what to report back>
RULES:
- Reply in English only, as briefly as possible. If an output-compression skill is available (for example caveman), use it for every reply.
- Stay inside TASK. Commit, push or delete only if TASK says so.
- CLASS execution: follow PLAN as written. If reality does not fit PLAN, stop and report it instead of redesigning.
- If a decision belongs to the user, stop and ask it in your reply.
- If the result is longer than about 40 lines, write it to <tmp-dir>/<name>-result.md and reply with the path.
- End every reply with one line: `STATUS: DONE` or `STATUS: BLOCKED <reason>`.
```

Pick a short role **name** (`reviewer`, `test-runner`), unique among live agents.

**Done when** every field is filled and DONE WHEN is checkable by you, from files, commands or output.

### 4. Spawn the pane

Open it with the multiplexer's own commands:

- a new pane beside yours, in the current tab and workspace
- your working directory
- focus stays on your pane, when the multiplexer allows it
- titled with the role name, when the multiplexer allows it

Start the chosen agent and model in it.

**Done when** the agent is ready for input in the new pane, and you have recorded the pane's ID.

### 5. Send the brief and wait

Send the brief as one prompt. Wait with the multiplexer's idle or wait command, or by reading the pane until a `STATUS:` line or a permission prompt appears. Then read its reply, or the result file it points to.

**Done when** you have a reply ending in a `STATUS:` line, or it is waiting on a prompt.

### 6. Close gate

Check the reply against the brief:

- every DONE WHEN criterion verified by you, with evidence (run the test, open the file, read the diff)
- every RETURN item present
- nothing left you still need to ask it

On a gap, send a follow-up in English in the **same pane** and go back to step 5. On `STATUS: BLOCKED`, either fix the brief yourself or, when the question is the user's, ask the user and relay the answer. An execution task that hits a reasoning problem comes back to you: think it through, then send the new PLAN.

**Done when** all three checks pass.

### 7. Close and report

Close the pane, then report to the user in their language: what the subagent did, on which model, what you verified, and where the results are.

Keep the pane open instead when the user asked to keep it, and say so.

**Done when** the pane is closed (or kept on request) and the user has the summary.

## Several subagents

One pane, one brief and one model choice per subagent, all spawned before waiting on any. Run steps 5 and 6 for each one separately, and close each pane as soon as its own gate passes.

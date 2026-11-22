---
name: delegate-to-pane
description: Decide how a spawned subagent is run when you delegate from inside any terminal multiplexer or agent workspace - its own visible pane in your workspace, an English brief, a model matched to the task class (research, reasoning, execution, review), event hooks that trigger follow-up skills or subagents, and a close gate on verified completion. Use when you delegate reasoning work to another agent in a pane, and when the user asks to delegate ("fai fare a un subagent", "delega") or to run agents in parallel. To start one known command or process, use run-in-pane instead.
---

# Delegate to a pane

A delegation policy. It decides where a subagent runs, how it is briefed, which model it gets, what happens on its events, and when it may close.

It works with any multiplexer. The pane commands belong to the multiplexer: learn them from its own skill or CLI help, and keep its rules as they are.

## Scope

You are the **parent**, the agent the user talks to. These rules shape only the **spawned chats**; your own chat with the user keeps its language, style and length, and the brief's RULES block never applies to you. A subagent that also has this skill follows its brief and uses the skill only to delegate further.

A **mechanical** task (one known command, no reasoning, no plan to write) needs no brief and no model choice: run it with the `run-in-pane` skill.

## Hard rules

1. **English only inside the spawned chat.** The brief, follow-ups and relayed answers are in English, because it costs fewer tokens. Your chat with the user keeps the user's language.
2. **Close gate.** A pane closes only when step 7 passes. A subagent that says "done" is a claim, not proof.
3. **Your panes only, by ID.** Record the ID the spawn command returns and close only recorded IDs, never one found by label or position. A pane you reused or found is not yours.
4. **Approvals belong to the user.** When the subagent waits at a permission or approval prompt, show it to the user and relay their answer. Start subagents with their normal permission prompts: use a skip-permissions or auto-approve flag only when the user asked for it.

## Steps

### 1. Find the multiplexer

When the session context already names the multiplexer and its list command answers, skip the detector. Otherwise run the one shipped with this skill:

```bash
bash assets/detect-multiplexer.sh
```

It checks the markers of over 20 multiplexers and agent workspaces, then the process tree. Read every line: `candidates:` and `ancestors:` can reveal a tool the script does not know yet.

Then read [ENVIRONMENTS.md](ENVIRONMENTS.md) for where its commands come from (its own skill first, then its help), its **level** (`split`, `tab`, `agent` or `none`), and whether it isolates agents in git worktrees. For a tool not listed there, read `<tool> --help`: a bare `<tool>` often opens its UI.

Find a command for each **capability** your level allows: open a pane (or tab, or agent session) with a working directory, run a command in it, set its title, send text and Enter, read its output, wait for idle (or poll the output), kill and close it by ID, list them, and know your own ID.

When a command fails with a permission or connection error, your sandbox is probably blocking the multiplexer's socket: ask the user to allow it, rather than concluding there is no multiplexer.

When the result is `unknown` with nothing in `candidates:` or `ancestors:`, ask the user once which multiplexer they are in, if any. At level `none`, or when the user says there is none, use your agent's own subagent mechanism, or work inline, and say so. Everything below still applies.

**Done when** you know the level and have a command for every capability it allows, or the user confirmed there is no multiplexer.

### 2. Read the delegation settings

Settings come from the user's request first, then a `## Delegation` section in the project's agent instructions (`AGENTS.md`, `CLAUDE.md` or your agent's equivalent), then the user's global instructions. They may set:

- the agent and model per task class (`research`, `reasoning`, `execution`, `review`, see step 3)
- **hooks**: what to run on a subagent's events. Read [HOOKS.md](HOOKS.md) when any are defined.

**Done when** you know which settings apply, or that none are set.

### 3. Classify and pick the model

The class says what kind of thinking the task needs, and so which model fits it:

| Class | The subagent... | Suggested tier |
| --- | --- | --- |
| `research` | reads, searches and summarises, changing nothing | middle |
| `reasoning` | designs, debugs or decides, with no plan yet | yours (top) |
| `execution` | follows a plan you wrote: files, changes and commands named | middle, small for trivial steps |
| `review` | critiques finished work (code review, security, tests) | top, ideally another family |

When a task fits two classes, take the higher tier. When in doubt, it is `reasoning`.

The settings choose agent and model per class, and they always win. Without a setting, follow the suggested tier inside your own family: the next model down for middle, the smallest for small.

Setups for Claude Code, Codex, opencode and a pi mix are in [MODELS.md](MODELS.md). Read it when the user asks to set up delegation, or when a setting names an agent whose model flag you don't know.

**Done when** the class, agent and model are chosen.

### 4. Write the brief

The subagent shares none of your memory. Fill this template in English, terse but complete:

```
CLASS: <research | reasoning | execution | review>
TASK: <one sentence>
CONTEXT: <paths, decisions, constraints, anything it cannot discover alone>
PLAN: <execution only: the exact steps, in order>
DONE WHEN: <checkable criteria, one per line>
RETURN: <exactly what to report back>
RULES:
- Reply in English only, as briefly as possible.
- Stay inside TASK. Commit, push or delete only if TASK says so.
- CLASS research or review: change nothing. Report findings with file paths or sources.
- CLASS execution: follow PLAN as written. If reality does not fit PLAN, stop and report it instead of redesigning.
- Start long-running processes (dev servers, studios, watchers) in a new visible pane beside yours, titled `<project>: <process>`, never in the background. List them in your reply.
- If a decision belongs to the user, stop and ask it in your reply.
- If the result is longer than about 40 lines, write it to <tmp-dir>/<name>-result.md and reply with the path.
- End every reply with one line: `STATUS: DONE` or `STATUS: BLOCKED <reason>`.
```

Pick a short role **name** (`login-builder`, `security-review`), unique among live agents.

**Done when** every field is filled and DONE WHEN is checkable by you, from files, commands or output.

### 5. Spawn the pane

With the multiplexer's commands, at the highest level it reaches: a pane beside yours (`split`), a new terminal or tab in the same workspace (`tab`), or a new agent session the app shows (`agent`). Use your working directory, and leave focus on your pane where the tool allows it. In rex or tmux, the `run-in-pane` skill ships `assets/pane.sh`: `open` prints the pane ID and records it, and `close` accepts only recorded IDs. Start the chosen agent and model in it. When the tool puts the agent in its own worktree, follow the worktree notes in [ENVIRONMENTS.md](ENVIRONMENTS.md).

Title the pane with the **agent's name**: `claude`, `codex`, `opencode`, `pi`, ... When several panes run the same agent, add the role: `codex: reviewer`. Keep titles ASCII: under a non-UTF-8 locale tmux turns other characters into `_`. Set it with the multiplexer's own pane-title or label command, after the agent has started: agents rewrite the terminal title, so a title set before the start gets overwritten.

**Done when** the agent is ready for input in the new pane, the pane shows its title, and you have recorded the pane's ID.

### 6. Send the brief and wait

Send the brief as one prompt, only once the agent shows its input prompt: before that it lands in a shell and runs as commands. Wait with the multiplexer's idle or wait command, or by reading the pane until a `STATUS:` line or a permission prompt appears. Then read its reply, or the result file it points to.

**Done when** you have a reply ending in a `STATUS:` line, or it is waiting on a prompt.

### 7. Close gate

Check the reply against the brief:

- every DONE WHEN criterion verified by you, with evidence (run the test, open the file, read the diff)
- every RETURN item present
- nothing left you still need to ask it

On a gap, send a follow-up in English in the **same pane** and go back to step 6. On `STATUS: BLOCKED`, fire the `blocked` event, then either fix the brief yourself or, when the question is the user's, ask the user and relay the answer. An execution task that hits a reasoning problem comes back to you: think it through, then send a new PLAN.

**Done when** all three checks pass.

### 8. Kill, fire events, report

Once the close gate passed and no hook needs this subagent again, **kill** it so the pane disappears: quit the agent with its own exit command (`/exit`, `/quit`, or `Ctrl-C` twice), close the pane by its recorded ID, then list the panes and force-kill that same ID if it is still there.

Then fire the `done` event: run every matching hook ([HOOKS.md](HOOKS.md)). Report to the user in their language: what the subagent did, on which model, what you verified, which hooks fired, and where the results are.

Keep the pane open instead only when the user asked to keep it, and say so.

**Done when** the pane no longer appears in the multiplexer's pane list (or is kept on request), every matching hook has run or been started, and the user has the summary.

## Several subagents

One pane, one brief and one model choice per subagent, all spawned before waiting on any. Run steps 6 to 8 for each one separately, killing each pane as soon as its own gate passes. When the last one closes, fire `all-done`.

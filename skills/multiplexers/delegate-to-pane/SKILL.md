---
name: delegate-to-pane
description: Decide how a spawned subagent is run when you delegate from inside any terminal multiplexer (herdr, Orca, rex, tmux, ...) - its own visible pane in your workspace, an English brief, a model matched to the task class (research, reasoning, execution, review), event hooks that trigger follow-up skills or subagents, and a close gate on verified completion. Use before spawning any subagent, including with your built-in subagent tool, and when the user asks to delegate ("fai fare a un subagent", "delega") or to run agents in parallel.
---

# Delegate to a pane

A delegation policy. It decides where a subagent runs, how it is briefed, which model it gets, what happens on its events, and when it may close.

It works with any multiplexer. The pane commands belong to the multiplexer: learn them from its own skill or CLI help, and keep its rules as they are.

## Scope: spawned chats only

You are the **parent**, the agent the user talks to. These rules shape only the **spawned chats**: what you send to your subagents and how they reply. Your own chat with the user stays exactly as it was before this skill: the user's language, your usual style and length, no output compression. The brief's RULES block is written for the subagent and never applies to you.

A subagent that also has this skill follows its brief. It uses this skill only to delegate further, and then only for the chats it spawns.

## Hard rules

1. **English only inside the spawned chat.** The brief, follow-ups and relayed answers are in English, because it costs fewer tokens. Your chat with the user keeps the user's language.
2. **Close gate.** A pane closes only when step 7 passes. A subagent that says "done" is a claim, not proof.
3. **Your panes only.** Close panes you created. Leave every other pane alone.
4. **Approvals belong to the user.** When the subagent waits at a permission or approval prompt, show it to the user and relay their answer.

## Steps

### 1. Find the multiplexer

Run the detector shipped with this skill:

```bash
bash assets/detect-multiplexer.sh
```

It checks known environment markers, then the process tree, and prints `multiplexer:`, the matching `marker:`, other `candidates:` that look like pane IDs, and the `ancestors:` chain. Read every line: a `candidates:` or `ancestors:` entry can reveal a multiplexer the script does not know yet.

Then learn its commands, from the first source that exists:

1. **Its skill.** Many multiplexers ship one for agents (herdr's `herdr`, Orca's `orca skills get orca-cli`, rex's agent skill).
2. **Its help.** `<tool> --help` or `<tool> help`. A bare `<tool>` often opens its UI, so always pass a help flag.

Find a command for each **capability**: split a new pane beside a given pane with a working directory, run a command in it, set its title, send text and Enter, read its output, wait for idle (or poll the output), kill its process and close it by ID, list panes, and know your own pane's ID.

When a command fails with a permission or connection error, your sandbox is probably blocking the multiplexer's socket: ask the user to allow it, rather than concluding there is no multiplexer.

When the result is `unknown` with nothing in `candidates:` or `ancestors:`, ask the user once which multiplexer they are in, if any. Use your agent's own subagent mechanism, or work inline, only when they say none or a capability is missing. Everything below still applies.

**Done when** every capability has a command, or the user confirmed there is no multiplexer.

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

The settings choose agent and model per class, and they always win. Without a setting, follow the suggested tier inside your own family, for example:

| You run on | Middle | Small |
| --- | --- | --- |
| Fable, Opus | Sonnet 5.5 | Haiku 5.5 |
| Astra | Sol | Luna |

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
- Reply in English only, as briefly as possible. If an output-compression skill is available (for example caveman), use it for every reply.
- Stay inside TASK. Commit, push or delete only if TASK says so.
- CLASS research or review: change nothing. Report findings with file paths or sources.
- CLASS execution: follow PLAN as written. If reality does not fit PLAN, stop and report it instead of redesigning.
- Start long-running processes (dev servers, studios, watchers) in a new visible pane beside yours, titled `<project> · <process>`, never in the background. List them in your reply.
- If a decision belongs to the user, stop and ask it in your reply.
- If the result is longer than about 40 lines, write it to <tmp-dir>/<name>-result.md and reply with the path.
- End every reply with one line: `STATUS: DONE` or `STATUS: BLOCKED <reason>`.
```

Pick a short role **name** (`login-builder`, `security-review`), unique among live agents.

**Done when** every field is filled and DONE WHEN is checkable by you, from files, commands or output.

### 5. Spawn the pane

With the multiplexer's commands: a new pane beside yours, in the current tab and workspace, in your working directory, leaving focus on your pane where the multiplexer allows it. Start the chosen agent and model in it.

Title the pane with the **agent's name**: `claude`, `codex`, `opencode`, `pi`, ... When several panes run the same agent, add the role: `codex · reviewer`. Set it with the multiplexer's own pane-title or label command, after the agent has started: agents rewrite the terminal title, so a title set before the start gets overwritten.

**Done when** the agent is ready for input in the new pane, the pane shows its title, and you have recorded the pane's ID.

### 6. Send the brief and wait

Send the brief as one prompt. Wait with the multiplexer's idle or wait command, or by reading the pane until a `STATUS:` line or a permission prompt appears. Then read its reply, or the result file it points to.

**Done when** you have a reply ending in a `STATUS:` line, or it is waiting on a prompt.

### 7. Close gate

Check the reply against the brief:

- every DONE WHEN criterion verified by you, with evidence (run the test, open the file, read the diff)
- every RETURN item present
- nothing left you still need to ask it

On a gap, send a follow-up in English in the **same pane** and go back to step 6. On `STATUS: BLOCKED`, fire the `blocked` event, then either fix the brief yourself or, when the question is the user's, ask the user and relay the answer. An execution task that hits a reasoning problem comes back to you: think it through, then send a new PLAN.

**Done when** all three checks pass.

### 8. Kill, fire events, report

Once the close gate passed and no hook needs this subagent again, **kill** it so the pane disappears and the UI stays clean:

1. Quit the agent with its own exit command (`/exit`, `/quit`), or `Ctrl-C` twice.
2. Close the pane by ID with the multiplexer's close or kill command.
3. List the panes. If it is still there, kill it with the multiplexer's force option.

Then fire the `done` event: run every matching hook ([HOOKS.md](HOOKS.md)). Report to the user in their language: what the subagent did, on which model, what you verified, which hooks fired, and where the results are.

Keep the pane open instead only when the user asked to keep it, and say so.

**Done when** the pane no longer appears in the multiplexer's pane list (or is kept on request), every matching hook has run or been started, and the user has the summary.

## Several subagents

One pane, one brief and one model choice per subagent, all spawned before waiting on any. Run steps 6 to 8 for each one separately, killing each pane as soon as its own gate passes. When the last one closes, fire `all-done`.

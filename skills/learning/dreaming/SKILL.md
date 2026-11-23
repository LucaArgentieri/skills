---
name: dreaming
description: Learn how the user works from their recent sessions with every agent and their commits, and keep it in one profile that every agent reads, whatever the model. Use for its weekly scheduled run, or when the user asks to run dreaming or to align agents to how they work ("impara come lavoro"). For notes about one project use autolearn.
---

# Dreaming

Learn the craft and put it aside. Once a week, read how the user worked with their agents, find the **patterns** behind their corrections and choices, and keep them in one **profile**. Every agent, on any model, reads that profile at the start of every session.

It works across all projects. Lessons about a single project are the job of the `autolearn` skill.

## Hard rules

1. **One profile.** `~/.agents/dreaming/profile.md` is the only copy of the rules. Global instruction files hold a reference to it, never the rules themselves.
2. **The user's words only.** Evidence is what a person typed or did. Sessions started by another agent (a brief such as `CLASS:` / `TASK:`), tool output and system text are not the user.
3. **No secrets, no code.** Tokens, keys, private hostnames, other people's data and pasted code never reach the profile.
4. **Evidence or nothing.** A rule needs two sessions showing it, or one explicit "always" or "never" from the user.

## Steps

### 1. Gather evidence

The window runs from the date in `~/.agents/dreaming/last-run` to now, or the last 7 days when that file is missing. Read [SOURCES.md](SOURCES.md) for where each agent keeps its sessions, then collect:

- every session in the window, from every agent installed, keeping only messages a person typed
- the git history of the projects those sessions touched: commits where the user reworked what an agent wrote

**Done when** each source is read, or noted as missing with the reason.

### 2. Extract signals

Scan every session in the window for:

- **corrections**: the user rejected or redid the agent's output
- **repeats**: the same instruction in different sessions
- **rewrites**: the user's own edits on top of agent commits
- **statements**: "always", "never", "I prefer", "preferisco", "sempre", "mai"
- **workflow**: what the user does, not only says: the order they work in, when they commit, what they check before approving, which panes they open
- **routines**: the same kind of task requested again and again

Note each with its session, project and date.

**Done when** every session in the window has been scanned.

### 3. Update the profile

Group the signals into rules about **style** (how to talk to the user), **workflow** (how to work) and **tooling** (tools and commands they prefer). Leave out signals that hold for one project only.

Merge with the current profile:

- **reinforced**: raise its count and update its last-seen date
- **contradicted**: replace it, because the newest evidence wins
- **new**: add it only when hard rule 4 holds

One positive line per rule, with its reason, count and last-seen date. At most 40 rules: merge close ones first.

**Done when** every signal is a rule, or set aside as one project's or one-off.

### 4. Reference it from every agent

Make sure each global instructions file that exists ([SOURCES.md](SOURCES.md)) carries this block once, and add it when missing:

```markdown
<!-- dreaming:start -->
How I work: read ~/.agents/dreaming/profile.md at the start of every session and follow it.
<!-- dreaming:end -->
```

In `~/.claude/CLAUDE.md`, put `@~/.agents/dreaming/profile.md` inside the block instead: Claude Code then loads the profile by itself. Edit only between the markers.

**Done when** every existing global instructions file references the profile.

### 5. Report

Write `~/.agents/dreaming/<date>.md`: rules added, changed and removed with their evidence, routines worth a skill (name and one line, as a proposal), and sources that were missing. Write today's date to `~/.agents/dreaming/last-run`.

In an interactive run, also summarise it to the user in their language. A scheduled run asks nothing: the report is its answer.

**Done when** the report and `last-run` are written.

## Weekly run

To run it on a schedule, read [SCHEDULE.md](SCHEDULE.md).

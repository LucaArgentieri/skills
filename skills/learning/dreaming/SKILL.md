---
name: dreaming
description: Study how the user works across recent agent sessions, projects and commits, and distil it into a working profile every agent loads, so agents need fewer corrections. Use when the user asks to run dreaming or to align agents to how they work ("impara come lavoro"), and for its weekly scheduled run. For lessons from the current session in one project use autolearn.
---

# Dreaming

Learn the craft and put it aside. While the user is away, read how they worked this week, find the **patterns** behind their corrections and choices, and write them into a **profile** that every agent loads at startup.

`autolearn` keeps per-project notes during a session. Dreaming works across projects and sessions, and promotes lessons that turn out to be about the user rather than one project.

## Hard rules

1. **Sources are read-only.** Transcripts, repos and `autolearn` notes are evidence. The only files you write are listed in steps 3 and 4.
2. **No secrets, no code.** Tokens, keys, private hostnames, other people's data and pasted code never reach the profile. Rules describe how the user works.
3. **Inside the markers only.** In each global instructions file, edit only between `<!-- dreaming:start -->` and `<!-- dreaming:end -->`.
4. **Evidence or nothing.** A rule needs two sessions showing it, or one explicit "always" or "never" from the user.

## Steps

### 1. Gather evidence

The window runs from the date in `~/.agents/dreaming/last-run` to now, or the last 7 days when that file is missing. Read [SOURCES.md](SOURCES.md) for where each agent keeps its transcripts and global instructions, then collect:

- every session transcript in the window, from every agent installed
- the `autolearn` notes of every project those sessions touched
- the git history of those projects: commits where the user reworked what an agent wrote

**Done when** each source is read, or noted as missing, with the reason.

### 2. Extract signals

Scan every session in the window for:

- **corrections**: the user rejected or redid the agent's output
- **repeats**: the same instruction in different sessions
- **rewrites**: the user's own edits on top of agent commits
- **statements**: "always", "never", "I prefer", "preferisco", "sempre", "mai"
- **routines**: the same kind of task requested again and again

Note each with its session, project and date, and a few words of quote.

**Done when** every session in the window has been scanned.

### 3. Distil rules

Group the signals into rules about **style** (how to talk to the user), **workflow** (how to work), and **tooling** (tools and commands the user prefers). A signal true for one project only goes into that project's `autolearn` notes instead, in their format.

Merge with the current profile:

- **reinforced**: raise its evidence count and update its last-seen date
- **contradicted**: replace it, because the newest evidence wins
- **new**: add it only when hard rule 4 holds

Write each rule as one positive line with its reason. Keep the profile under 40 rules: merge close ones first.

**Done when** every signal is used in a rule, sent back to a project, or set aside as one-off.

### 4. Write

1. `~/.agents/dreaming/profile.md` is the **single source**: every rule with its evidence count and last-seen date.
2. Copy the rule lines only, without evidence, into the marked block of each global instructions file that exists ([SOURCES.md](SOURCES.md)). Back the file up first as `<file>.dream-<date>.bak`. Create the block at the end of the file when it is missing:

   ```markdown
   ## How I work
   <!-- dreaming:start -->
   - ...
   <!-- dreaming:end -->
   ```

3. Write today's date to `~/.agents/dreaming/last-run`.

**Done when** every existing global instructions file carries the same block as the profile.

### 5. Propose skills

For each **routine** seen three times or more in the window, propose a skill: a name, one line on what it would do, and the sessions it came from. Propose only. Creating it is the user's call.

**Done when** every routine is either proposed or found too varied to automate.

### 6. Report

Write `~/.agents/dreaming/<date>.md`: rules added, changed and removed, each with its evidence; skill proposals; sources that were missing.

In an interactive run, also summarise it to the user in their language. A scheduled run asks nothing: the report is its answer.

**Done when** the report exists and, in an interactive run, the user has the summary.

## Weekly run

To run it on a schedule, read [SCHEDULE.md](SCHEDULE.md).

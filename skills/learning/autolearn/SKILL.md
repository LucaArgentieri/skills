---
name: autolearn
description: Keep private notes on how agents should work for this user in this project, learned from their corrections, rewrites and confirmations, and load them at the start of every session. Use at the start of work in a git project, when the user corrects you, repeats an instruction or rewrites your work ("no, così", "te l'ho già detto"), when they confirm a non-obvious choice, or when asked to save what was learned. For habits across all projects use dreaming.
---

# Autolearn

Every correction is a **lesson** about how the user wants agents to work in this project. This skill keeps those lessons as **notes**: agent instructions, private to the user, outside the repository.

Notes are not team documentation. They describe the user's workflow and how agents should fit it, never project rules for other developers. Habits that hold in every project are the job of the `dreaming` skill, which reads these notes and promotes them.

## Hard rules

1. **Outside the repository.** Notes live only in the file `assets/notes-path.sh` prints. Repository files (`AGENTS.md`, `CLAUDE.md`, READMEs) stay untouched.
2. **Agent behaviour only.** Each note says what an agent should do. Facts that every developer needs belong in the team's docs: mention them to the user instead.
3. **No secrets.** Tokens, keys, passwords, personal data and private hostnames never go into a note.

## Steps

### 1. Load

At the start of work in a git project, find and read this project's notes:

```bash
bash assets/notes-path.sh
```

It prints one path per repository, the same in every worktree and clone (for example `~/.agents/autolearn/github.com-owner-repo.md`). Read the file when it exists and follow its notes for the whole session.

On first use, make sure every agent loads the notes: add this block at the end of each global instructions file that exists, unless it is already there.

```markdown
<!-- autolearn:start -->
In a git project, before starting work, use the `autolearn` skill to load your notes for that project, and to record lessons when the user corrects you.
<!-- autolearn:end -->
```

Global files: `~/.claude/CLAUDE.md` (Claude Code), `~/.codex/AGENTS.md` (Codex), `~/.config/opencode/AGENTS.md` (opencode), `~/.pi/agent/AGENTS.md` (pi). Edit only between those markers.

**Done when** the notes are read (or there are none yet), and every existing global file carries the block.

### 2. Catch signals

- **Correction**: you worked one way, the user wanted another.
- **Repeat**: the user said the same thing twice.
- **Rewrite**: the user edited what you produced. `git diff` on files you touched shows how.
- **Confirmation**: the user approved a non-obvious choice ("perfetto, così").
- **Workflow**: how the user wants a step done here: when to commit, what to show before going on, which pane runs what.

A signal becomes a note only when it passes three tests:

- **Agent behaviour**: it tells an agent how to act. "The API uses REST" fails; "When changing the API: show me the diff before running migrations" passes.
- **Next week**: it would still hold in a different task. "Make this button red" fails.
- **Verified**: the user said it, or you reproduced it. A guess about why something broke is not a note.

**Done when** every signal of the session is a note or dropped for a stated reason.

### 3. Write the note

Condition first, so the next agent recognises the moment it applies. In English, under about 30 words:

```
- When <situation>: <what to do>. Why: <reason>. (<n>×, <date>)
```

- `- When a feature is done: start the dev server in a pane and wait for my check before committing. Why: I review UI by eye. (3×, 2026-11-23)`
- `- When editing packages/web styles: use tokens from src/theme.ts. Why: I rejected hard-coded hex. (2×, 2026-11-20)`

A new file starts with `# Autolearn notes` and a line naming the project. Before adding a note:

- **same lesson**: raise its count, update the date, keep the clearer wording
- **contradicts a note**: replace it, because the user's latest word wins

Write each note when it happens, so nothing is lost if the session ends.

**Done when** the lesson is in the file exactly once, and no note contradicts another.

### 4. Prune

Each time you write, check the whole file:

- a note naming a path, script or command that no longer exists: remove it
- more than 30 notes: merge the closest ones, then drop those with the lowest count and the oldest date

**Done when** every note refers to things that exist, and the file has at most 30 notes.

### 5. Report

In your final summary, in the user's language: the notes added, changed or removed this session.

**Done when** the user has seen every change to the notes.

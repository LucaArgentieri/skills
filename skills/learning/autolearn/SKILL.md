---
name: autolearn
description: Turn what the user taught you in this project into short when-then notes in its agent instructions, so the next session starts aligned. Use when the user corrects you, repeats an instruction or rewrites your work ("no, così", "te l'ho già detto"), confirms a non-obvious choice, when a task ends, or when asked to save what was learned. For habits across all projects use dreaming.
---

# Autolearn

Every correction is a **lesson**. This skill writes each one as a **note** in the project's agent instructions, which every agent loads at the start of the next session.

It covers one project. How the user works across all projects is the job of the `dreaming` skill, which reads these notes and promotes the ones that turn out to be about the user.

## Hard rules

1. **Inside the markers only.** Edit only between `<!-- autolearn:start -->` and `<!-- autolearn:end -->`. Every other line of the file is the user's.
2. **No secrets.** Tokens, keys, passwords, personal data and private hostnames never go into a note.
3. **The user commits.** Leave the change uncommitted.

## Where notes live

The `AGENTS.md` nearest to what the lesson is about: the root one for the whole project, a package's own `AGENTS.md` for a lesson about that package only. Create the file and the block when missing, with the pointer line above it:

```markdown
## Learned

When the user corrects you, repeats an instruction or rewrites your work, record it with the `autolearn` skill.

<!-- autolearn:start -->
- When running tests locally: use `pnpm test:unit`. Why: `pnpm test` needs Docker. (1×, 2026-11-20)
<!-- autolearn:end -->
```

The pointer line is what makes the next agent use this skill: it sits in a file that is always loaded.

When the project has a `CLAUDE.md` that neither imports (`@AGENTS.md`) nor mentions `AGENTS.md`, ask the user once whether to add `@AGENTS.md` to it.

## Signals

- **Correction**: you did X, the user wanted Y.
- **Repeat**: the user said the same thing twice.
- **Rewrite**: the user edited code you wrote. `git diff` on files you touched shows what they changed.
- **Confirmation**: the user approved a non-obvious choice ("perfetto, così"). Keeps the next agent from undoing it.
- **Gotcha**: a command or path that failed, then worked another way.

## Steps

### 1. Filter

A signal becomes a note only when it passes both tests:

- **Next week**: it would still be true and useful in a different task. "Make this button red" fails, "Buttons use the `variant` prop, not classes" passes.
- **Verified**: the user said it, or you reproduced it (the command really fails, the path really exists). A guess about why something broke is not a note.

Skip what the repo already says (README, config, scripts) and habits that apply to every project (`dreaming` collects those).

**Done when** every signal of the session is a candidate note or dropped for a stated reason.

### 2. Write the note

Condition first, so the next agent recognises the moment it applies. In English, under about 30 words:

```
- When <situation>: <what to do>. Why: <reason>. (<n>×, <date>)
```

- `- When adding colours: use the tokens in src/theme.ts. Why: hard-coded hex was rejected. (2×, 2026-11-20)`

Compare with the block before writing:

- **same lesson**: raise its count, update the date, keep the clearer wording
- **contradicts a note**: replace it, because the user's latest word wins
- **contradicts the user's own text in the file**: write nothing and ask the user which one holds
- **already said elsewhere in the file**: skip it

Write each note when it happens, so nothing is lost if the session ends.

**Done when** the lesson is in the block exactly once, and no note contradicts another or the rest of the file.

### 3. Prune

Each time you write, check the whole block:

- a note naming a path, script or command that no longer exists: remove it
- more than 30 notes: merge the closest ones, then drop those with the lowest count and the oldest date

**Done when** every note refers to things that exist, and the block has at most 30 notes.

### 4. Report

In your final summary, in the user's language: the notes added, changed or removed this session, and the file.

**Done when** the user has seen every change to the block.

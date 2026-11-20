---
name: autolearn
description: Turn what the user taught you in this session into short rules in the project's agent instructions, so the next session in this project starts aligned. Use when the user corrects you or repeats an instruction ("no, così", "te l'ho già detto"), when a task in this project ends, or when the user asks to save what was learned. For habits across all projects use dreaming.
---

# Autolearn

Every correction is a **lesson**. This skill writes each one, as a one-line rule, into the project's agent instructions, where every agent reads it at the start of the next session.

It covers one project and the current session. How the user works across all projects is the job of the `dreaming` skill, which also reads what this skill writes.

## Hard rules

1. **Inside the markers only.** Edit only between `<!-- autolearn:start -->` and `<!-- autolearn:end -->`. Every other line of the file is the user's.
2. **No secrets.** Tokens, keys, passwords, personal data and hostnames that look private never go into a lesson.
3. **The user commits.** Leave the change uncommitted and say what you added.

## Where lessons live

`AGENTS.md` at the project root, read by most agents. Create the file and the block when missing:

```markdown
## Learned

<!-- autolearn:start -->
- Run `pnpm test:unit` before pushing: `pnpm test` needs Docker, which CI lacks. (2026-11-20)
<!-- autolearn:end -->
```

When the project has a `CLAUDE.md` that neither imports (`@AGENTS.md`) nor mentions `AGENTS.md`, ask the user once whether to add `@AGENTS.md` to it, so Claude Code loads the lessons too.

## What counts as a lesson

- **A correction**: you did X, the user wanted Y.
- **A repeated instruction**: the user said the same thing twice.
- **A hard-won fact**: a command that fails, a hidden convention, a gotcha that cost a retry.

Leave out what the repo already says (README, config, scripts), details of one task only, and habits that apply to every project (those are `dreaming`'s).

## Steps

### 1. Capture

When a lesson happens, write it at once, so nothing is lost if the session ends. When a task ends, scan the session for lessons you missed.

**Done when** every correction and repeated instruction of the session has been considered.

### 2. Write the rule

One line, imperative, positive, with the reason after a colon, under about 25 words, dated:

- `- Use the design tokens in src/theme.ts for colours: hard-coded hex values were rejected twice. (2026-11-20)`

Before adding it, compare with the block:

- **same meaning**: keep one line, with the newer date and the clearer wording
- **contradiction**: replace the old line, because the user's latest word wins
- **already covered elsewhere in the file**: skip it

Keep the block under 30 lines. Past that, merge similar lines and drop the one least likely to matter again.

**Done when** the lesson is in the block exactly once, and no line contradicts another.

### 3. Tell the user

One line, in their language: the rule you added or changed, and the file.

**Done when** the user has seen every line you wrote this session.

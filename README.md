<p>
  <a href="https://lucaargentieri.github.io">
    <img src=".github/assets/squircle.svg" alt="" width="72" height="72">
  </a>
</p>

# Skills

Agent skills I use for my own work. Small, single-purpose, and easy to adapt.

## Install

The skills follow the open [Agent Skills](https://agentskills.io) format, so they work in Claude Code, Codex, opencode, Cursor and any other compatible agent, whatever the model behind it.

Any agent, as editable files:

```bash
npx skills@latest add LucaArgentieri/skills            # pick the agents interactively
npx skills@latest add LucaArgentieri/skills -a codex   # or name one
```

From a local clone, kept in sync by `git pull` (links into `~/.claude/skills` and `~/.agents/skills`):

```bash
scripts/link-skills.sh
```

Claude Code, as a plugin:

```bash
claude plugin marketplace add LucaArgentieri/skills
claude plugin install lucaargentieri-skills@lucaargentieri
```

## Skills

### [Publishing](./skills/publishing/README.md)

- **[ebook-typesetting](./skills/publishing/ebook-typesetting/SKILL.md)**: Typeset an ebook as a classic print-style PDF with HTML + Paged.js, with an illustrated cover and optional EPUB export.

### [Multiplexers](./skills/multiplexers/README.md)

- **[delegate](./skills/multiplexers/delegate/SKILL.md)**: Run a subagent in its own visible multiplexer pane with an English brief, a model matched to the task class (research, reasoning, execution, review), event hooks and a close gate on verified completion. Invoked by name, never by the agent on its own.
- **[run-in-pane](./skills/multiplexers/run-in-pane/SKILL.md)**: Start dev servers, watchers, tunnels and other commands that keep running in visible, titled panes the user can watch and stop, instead of the background. Works in any terminal tool through adapter files.

### [Learning](./skills/learning/README.md)

- **[autolearn](./skills/learning/autolearn/SKILL.md)**: Private, per-project notes on how agents should work for you, learned from corrections, rewrites and confirmations, loaded at the start of every session.
- **[dreaming](./skills/learning/dreaming/SKILL.md)**: Weekly: learn how you work from your sessions with every agent, and keep it in one profile every agent reads, whatever the model.

## Tests

```bash
bash tests/run.sh
```

- `tests/lint-skills.py` checks every skill against the checklist in `AGENTS.md`: name, description, READMEs, plugin manifest, Codex metadata, links, harness-specific names.
- `tests/autolearn.test.sh` checks that `notes-path.sh` gives one notes file per repository, the same across worktrees, clones and URL forms, with no credentials in the path.
- `tests/pane.test.sh` checks `pane.sh` (ledger, adapters, self-location) on a fake adapter and on real rex and tmux; `tests/herdr.test.sh` runs only inside a herdr pane.
- `tests/tmux-e2e.test.sh` runs the pane flows of `delegate` and `run-in-pane` on a real tmux server, with a fake agent and a local dev server.

They also run on every push and pull request.

## Writing a new skill

The rules live in [AGENTS.md](./AGENTS.md), read by Codex and most agents. `CLAUDE.md` imports it for Claude Code.

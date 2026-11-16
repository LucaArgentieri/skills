<p>
  <a href="https://lucaargentieri.github.io">
    <img src=".github/assets/squircle.svg" alt="" width="72" height="72">
  </a>
</p>

# Skills

Agent skills I use for my own work. Small, single-purpose, and easy to adapt.

## Install

Any agent, as editable files:

```bash
npx skills@latest add LucaArgentieri/skills
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

Coming soon: herdr, rex.

## Writing a new skill

The rules live in [CLAUDE.md](./CLAUDE.md) (also linked as `AGENTS.md`), so any agent working in this repo follows them.

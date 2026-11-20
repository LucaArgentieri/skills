# Sources

Read in step 1 and step 4. Agents change their storage layout between versions: confirm each path with `ls` before relying on it. For an agent not listed, look in its data folder (`~/.<agent>`, `~/.config/<agent>`, `~/.local/share/<agent>`) or its docs.

## Session transcripts

| Agent | Where |
| --- | --- |
| Claude Code | `~/.claude/projects/<project-path-with-dashes>/*.jsonl` |
| Codex | `~/.codex/sessions/<yyyy>/<mm>/<dd>/*.jsonl` (`$CODEX_HOME` moves it) |
| opencode | `~/.local/share/opencode/storage/` (sessions, messages and parts as JSON) |
| pi | `~/.pi/agent/sessions/` |

Use file modification times to keep only the window. JSONL files can be large: filter to the user's messages first (`jq`, `grep`), then read around the hits.

## Global instructions

Files each agent loads in every project. Dreaming writes its block into each one that exists, and creates none.

| Agent | File |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| opencode | `~/.config/opencode/AGENTS.md` |
| pi | `~/.pi/agent/AGENTS.md` |

## Lesson blocks

The `autolearn` block of a project sits in its `AGENTS.md`, between `<!-- autolearn:start -->` and `<!-- autolearn:end -->`. The project path comes from the transcript (Claude Code encodes it in the folder name, the others record a `cwd`).

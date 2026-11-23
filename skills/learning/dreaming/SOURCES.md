# Sources

Read in steps 1 and 4. Agents change their storage layout between versions: confirm each path with `ls` before relying on it. For an agent not listed, look in its data folder (`~/.<agent>`, `~/.config/<agent>`, `~/.local/share/<agent>`) or its docs.

## Session transcripts

| Agent | Where |
| --- | --- |
| Claude Code | `~/.claude/projects/<project-path-with-dashes>/*.jsonl` |
| Codex | `~/.codex/sessions/<yyyy>/<mm>/<dd>/*.jsonl` (`$CODEX_HOME` moves it) |
| opencode | `~/.local/share/opencode/storage/` (sessions, messages and parts as JSON) |
| pi | `~/.pi/agent/sessions/` |

Use file modification times to keep only the window. Files can be large: filter to messages a person typed first (`jq`, `grep`), then read around the hits. Skip a session whose first message is a brief from another agent (`CLASS:`, `TASK:`): it is a subagent, not the user.

## Global instructions

Files each agent loads in every project. Dreaming adds its reference block to each one that exists, and creates none.

| Agent | File |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| opencode | `~/.config/opencode/AGENTS.md` |
| pi | `~/.pi/agent/AGENTS.md` |

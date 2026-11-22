# Environments

Read after the detector names a multiplexer or agent workspace (ADE). For each one: where its commands come from, the best **level** it reaches, and whether it isolates agents in git worktrees. The commands themselves stay in each tool's own skill or help.

## Levels

| Level | What you can open | Use it for |
| --- | --- | --- |
| `split` | a pane beside yours, in the same tab | subagents and processes, the default |
| `tab` | a new visible terminal, tab or canvas node in the same workspace | the same, when there is no split |
| `agent` | a new agent session or thread the app shows, with no raw terminal | subagents only |
| `none` | nothing an agent can drive | your own subagent mechanism, or inline, and say so |

Use the highest level the tool reaches. Facts checked against each tool's source or docs in November 2026; when a tool's help disagrees, its help wins.

## Known tools

| Tool | Commands from | Level | Worktree per agent |
| --- | --- | --- | --- |
| herdr | its `herdr` skill, `herdr --help` | split | optional |
| Orca | `orca skills get orca-cli` (`orca-ide` on Linux outside Orca, or `$ORCA_CLI_COMMAND`) | split | yes |
| rex | `rex skill show`, `rex help` | split | no |
| cmux | its `cmux` skill, `cmux --help` | split | no |
| Superset / Paradev | its `panes` skill, `superset --help` | split | yes |
| Sidecar | `sidecar agents` | split | optional |
| amux | `amux --skill`; panes through plain tmux, already pointed at amux's own server | split | yes |
| dmux | plain tmux | split | yes |
| Claude Squad | plain tmux | split | yes |
| Cyclops | its `cyclops` skill for messages; panes through plain tmux | split | not documented |
| zellij, WezTerm, kitty, tmux, screen | `<tool> --help` or `man <tool>` | split | no |
| Muxy | its `muxy-cli` skill (`muxy install-skills`) | tab | optional |
| Pane | its `pane` skill, `runpane --help` | tab | yes |
| Paseo | its `paseo` skill, `paseo --help` | tab | optional |
| NodeTerm | its `manage-nodeterm-canvas` skill | tab | optional |
| Craig | `craig --help` | agent | yes |
| T3 Code | `t3 --help`, its MCP tools | agent | optional |
| Conductor | none local | none | yes |

When a tool's skill sets its own rules (for example "message agents with the tool's agent command, not raw input", or "rename sessions only through the tool's CLI"), follow them.

## Worktree isolation

When a subagent lands in its own git worktree, its changes live on another branch. Put the worktree path and branch in the brief's CONTEXT, run the close gate's checks inside that worktree, and report the branch to the user. Bringing the changes back (merge, cherry-pick) is the user's call, unless the delegation settings say otherwise.

# Adapters

`assets/pane.sh` knows no terminal tool by name. A tool is one file in `assets/adapters/<tool>.sh` (or in `$PANE_ADAPTER_DIR`, read first). Read this when `pane.sh` exits 3: you are in a tool that has no adapter yet, and writing one takes a few minutes.

## Contract

The file defines these functions. `pane.sh` sources it in a subshell per call, so nothing leaks between adapters.

| Function | Does | Prints / returns |
| --- | --- | --- |
| `pane_available` | the tool's CLI is installed | exit 0 or not |
| `pane_marker` | the environment says we run in one of its panes (a variable the tool sets) | exit 0 or not |
| `pane_locate PIDS` | find our pane by matching the process ids in `PIDS` (our ancestors) to its panes' processes | `KEY=VALUE` lines to export (the variables the other functions need), exit 1 if none |
| `pane_session` | a name for the tool's session, used to keep one ledger per session | one line |
| `pane_open TITLE CWD DIR CMD...` | split a pane (`DIR` is `right` or `below`) in `CWD`, title it, run `CMD` as a plain foreground command, leave focus where it was | the new pane's ID, alone on stdout |
| `pane_read ID LINES` | the last `LINES` lines of the pane, soft wraps joined | text |
| `pane_alive ID` | the pane still exists | exit 0 or not |
| `pane_close ID` | close the pane, which ends its process | exit 0 or not |

## Write one

1. Learn the tool's commands from its own skill, then its `--help`. The installed binary is the authority: do not copy commands from memory.
2. Copy a bundled adapter as a starting point and replace the commands. Parse JSON with `python3 -I`, never by pattern.
3. Pass the command as separate words, quoted with `printf '%q '` when the tool takes one string.
4. Make `pane_locate` independent of environment variables: some agents pass on none of them.
5. Try it by forcing it, from inside a pane of the tool:

```bash
PANE_ADAPTER=./mytool.sh bash assets/pane.sh open --title "t: test" --wait "ready" -- sh -c 'echo ready; sleep 30'
PANE_ADAPTER=./mytool.sh bash assets/pane.sh close --all
```

6. Save it as `<tool>.sh` in `$PANE_ADAPTER_DIR`, or in `assets/adapters/` in a pull request. From then on `pane.sh` picks it by itself.

**Done when** `open --wait` returns the pane ID and the output, `close` of that ID works, and `close` of a pane you did not open is refused (exit 4).

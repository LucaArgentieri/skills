# Weekly run

Read when the user wants dreaming on a schedule. Pick one way, then confirm with the user the day and time (default: Monday morning, before work starts).

## Your agent's scheduler

When your agent has its own scheduled tasks, use it with the prompt `Run the dreaming skill.` It keeps the agent's permissions and login.

## cron

Any agent with a headless mode works. One line in `crontab -e`, for example every Monday at 08:17:

```cron
17 8 * * 1  cd ~ && claude -p "Run the dreaming skill." >> ~/.agents/dreaming/cron.log 2>&1
```

The same line with another agent:

| Agent | Command |
| --- | --- |
| Claude Code | `claude -p "Run the dreaming skill."` |
| Codex | `codex exec "Run the dreaming skill."` |
| opencode | `opencode run "Run the dreaming skill."` |
| pi | `pi -p "Run the dreaming skill."` |

Check the headless flag with `<agent> --help`. cron runs with a short `PATH`: use the agent's full path (`which claude`) when the log shows "command not found".

A headless run has no one to approve prompts. Grant only what dreaming needs: read access to the sources in [SOURCES.md](SOURCES.md), and write access to `~/.agents/dreaming/` and the global instructions files. Each agent sets this differently: see its permission or sandbox settings.

**Done when** the job is installed and one manual run of the same command wrote a report in `~/.agents/dreaming/`.

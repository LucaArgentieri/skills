# Hooks

Read when the delegation settings define hooks. A hook runs a skill or spawns a subagent when a subagent's event fires.

## Events

| Event | Fires when |
| --- | --- |
| `spawned` | the subagent is ready in its pane and has the brief |
| `blocked` | it replied `STATUS: BLOCKED` |
| `done` | its close gate passed and its pane closed |
| `all-done` | the last of several parallel subagents is done |

## Writing a hook

One line per hook, in plain words, in the `## Delegation` section:

```markdown
## Delegation

- execution: opencode, model <free-or-open-weight-model>
- reasoning: same as mine
- on done, when the task built or changed login, auth or sessions: spawn a reasoning subagent for a security review of the changed files
- on done, when code changed: run the `code-review` skill on the diff
- on all-done: run the test suite and report failures
- on blocked: tell me at once, even mid-task
```

Each hook has three parts:

- **on** `<event>`
- **when** `<condition>`: optional, judged by you from the brief, the diff and the reply
- **then** an action: run a skill (by name), spawn a subagent (with a task), or do something yourself

## Running hooks

1. After an event, check every hook for that event against its condition. Say in one line which matched and why the others did not.
2. **Run a skill**: invoke it with the finished subagent's results as input.
3. **Spawn a subagent**: run this skill again from step 3, with a brief built from the hook's task plus the finished subagent's RETURN and changed files. It gets its own pane, class, model and close gate.
4. Matching hooks with no dependency on each other start together.

**Done when** every matching hook has run, or its subagent is spawned and waited on like any other.

## Chains

A subagent spawned by a hook fires its own events, so hooks can chain (login built, then security review, then a fix). A chain stops at depth 3. When the limit stops one, tell the user what would have fired next.

A hook never fires on the subagent it spawned for the same event and condition, so a hook cannot loop on itself.

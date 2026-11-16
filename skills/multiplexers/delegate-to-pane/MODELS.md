# Model setups

Read when the user asks to set up delegation, or when a setting names an agent whose model flag you don't know. Each block is a `## Delegation` section for the project's agent instructions (`AGENTS.md`, `CLAUDE.md`, ...). Hooks can sit in the same section ([HOOKS.md](HOOKS.md)).

Model names change often. Placeholders in `<angle brackets>` stand for whatever the agent's own model picker lists today. Check flags with `<agent> --help`.

## Claude Code only

```markdown
## Delegation

- research: claude --model sonnet
- reasoning: same as mine
- execution: claude --model sonnet, or claude --model haiku for trivial steps
- review: claude --model opus
```

`--model` takes an alias (`opus`, `sonnet`, `haiku`) or a full ID (`claude-sonnet-5-5`).

## Codex only

```markdown
## Delegation

- research: codex --model <middle-model>
- reasoning: same as mine
- execution: codex --model <middle-model>, or <small-model> for trivial steps
- review: codex --model <top-model> -c model_reasoning_effort=high
```

`-c key=value` overrides one config value for that run, such as the reasoning effort.

## opencode with free and open-weight models

```markdown
## Delegation

- research: opencode --model <provider>/<free-model>
- reasoning: same as mine
- execution: opencode --model <provider>/<open-weight-model>
- review: opencode --model <provider>/<top-model>
```

`--model` takes `provider/model`, as listed by `opencode models`. Free trial models suit research; an open-weight coder (DeepSeek, Qwen, Kimi, ...) suits execution.

## Mix with pi

One agent per class, each where it is strongest or cheapest:

```markdown
## Delegation

- research: opencode --model <provider>/<free-model>
- reasoning: same as mine (Claude Code, Opus)
- execution: pi --model <provider>/<open-weight-model>:low
- review: codex --model <top-model>
```

pi's `--model` takes `provider/id` with an optional `:<thinking>` level (`:low`, `:high`).

## Reading a setting

- `same as mine`: your own agent and model.
- An agent with no model: that agent's default model.
- A model with no agent: your own agent, started with that model.
- A class with no line: the suggested tier from the skill's step 3.

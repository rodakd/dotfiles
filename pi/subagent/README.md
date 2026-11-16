# Pi subagents (vendored)

Vendored from Pi's official example
`examples/extensions/subagent/` @ release 1.5.2. Upstream changes land with
`pi update`: re-diff against the new release's example dir and port changes.

## What this adds

- **`subagent` tool** — the main model can delegate to specialized agents
  running in isolated `pi` subprocesses. Three modes: single (`{ agent, task }`),
  parallel (`{ tasks: [...] }`, max 8 / 4 concurrent), and chain
  (`{ chain: [...] }` with a `{previous}` output placeholder).
- **Agents** (`~/.pi/agent/agents/*.md` → `pi/agents/` here):
  `scout` (recon, read-only+), `planner` (read-only planning),
  `reviewer` (review), `worker` (general-purpose, all tools).
- **Workflow prompts** (`~/.pi/agent/prompts/*.md` → `pi/prompts/` here):
  `/implement` (scout→planner→worker), `/scout-and-plan` (scout→planner),
  `/implement-and-review` (worker→reviewer→worker).

**Local changes vs upstream**

1. Stripped the sample agents' `model:` pins (claude-haiku/sonnet) so agents
   inherit this session's active model and thinking level — except `worker`,
   pinned to `model: openrouter/deepseek/deepseek-v4.1-flash`. Always pin the
   **provider-qualified** form (`provider/model-id`): a bare id can be
   ambiguous across authenticated providers and the child then exits with a
   startup error (e.g. bare `z-ai/glm-5.3-flash` matched both `nvidia` and
   `openrouter`).
2. The tool description now enumerates the discovered agent roster
   (upstream lists only the modes), so the model can delegate on its own
   initiative instead of discovering agents by trial and error.
3. The `settings.json` `defaultModel: "z-ai/glm-5.3"` only works bare because
   openrouter alone offers that id.
4. **Recursion guard**: spawned children get `PI_SUBAGENT_DEPTH` in their
   environment, and the extension does not register the `subagent` tool in a
   process that is itself a subagent (`depth >= MAX_SUBAGENT_DEPTH`, default 1).
   Upstream children run plain `pi` with the same agent dir, so without this a
   subagent could spawn grandchildren, and those again — unbounded, each a
   full billed `pi` run (×8 per call in parallel mode). With the guard the
   model in a child session never sees the tool, so nesting is structurally
   impossible; a child's bash also inherits the marker, so `pi -p` from inside
   a child cannot resume the chain. Raise `MAX_SUBAGENT_DEPTH` in
   `pi/subagent/index.ts` to allow deliberate deeper nesting.

## Verified behavior

- Fresh `pi` (depth 0): `subagent` in the tool list; parent → worker dispatch
  works end-to-end.
- Depth-1 child (`PI_SUBAGENT_DEPTH=1`): tool list is `read, bash, edit, write`
  — no `subagent`.
- Parent → worker → “spawn another worker”: child cannot — reports no such
  tool and confirms the env marker; no grandchild process.

Project-local agents (`.pi/agents/*.md` in a repo) are **not** loaded by
default — the tool passes `agentScope: "user"` unless you say otherwise. That
is the safe default: a repo you clone could otherwise ship prompts that run
arbitrary bash through subagents.

## Layout & symlinks

```
~/.pi/agent/extensions/subagent -> ~/repos/dotfiles/pi/subagent
~/.pi/agent/agents/*.md         -> ~/repos/dotfiles/pi/agents/*.md
~/.pi/agent/prompts/*.md       -> ~/repos/dotfiles/pi/prompts/*.md
```

## Cost model

Each subagent is a full `pi` run: its own context window, its own API usage.
Child usage is shown per-result but **not** added to this session's totals.
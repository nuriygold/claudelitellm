# claudelitellm

`claudelitellm` is not a stock Claude Code install.
`claudelitellm` is a local launcher that runs Claude Code against a LiteLLM proxy through a small local filtering proxy.

It is a local launcher that starts Claude Code inside a controlled wrapper:

- Claude Code talks to a temporary local HTTP filter proxy
- that proxy forwards to an existing LiteLLM instance
- LiteLLM then routes to the actual upstream model provider
- Claude runs under a clean temporary `HOME`
- MCP servers are injected from a dedicated `claudelitellmmcps.json` file

In other words, this build is better understood as a Claude Code-compatible agent shell running through local infrastructure, not as the traditional Claude consumer app flow.

## How this build works

At runtime `bin/claudelitellm` does all of the following:

1. checks that the upstream LiteLLM `/v1/models` endpoint is reachable
2. prompts for `LITELLM_KEY` when LiteLLM requires auth
3. starts a temporary local proxy on `127.0.0.1:<FILTER_PORT>`
4. strips `output_config` from JSON requests before forwarding them upstream
5. creates a clean temporary `HOME`
6. overlays `.claude` and `.codex` config into that temporary home
7. launches `claude` with `ANTHROPIC_BASE_URL` pointed at the local filter proxy
8. passes `--mcp-config` with the resolved `claudelitellmmcps.json` path when available

This means the launcher itself is the product. There is no separate application server or library layer that owns this behavior.

## How this differs from traditional Claude Code

Compared with a normal Claude Code setup, this launcher has several important differences:

- it does not talk directly to Anthropic by default
- it uses LiteLLM as the model backend
- it rewrites requests through a local compatibility proxy
- it launches in a clean temporary `HOME` instead of reusing your normal Claude session state
- it can run without the normal Claude consumer login flow because auth can come from local wrapper configuration and API-style credentials
- MCP loading is driven by a dedicated MCP config file instead of relying only on standard local Claude registration

Practically, treat this environment as a wrapped Claude runtime with special config resolution, not as a plain `claude` install.

## Files that matter

- `bin/claudelitellm` - launcher script, filter-proxy generator, clean-home setup, Claude invocation, MCP injection
- `bin/bootstrap-claude-config` - copies your real MCP config into this repo for local use without committing secrets
- `config/litellm.config.yaml.example` - example LiteLLM config
- `.claude/settings.local.json` - repo-local Claude settings used by default
- `.claude/claudelitellmmcps.json.example` - safe MCP starter config you can copy locally

## Expected local dependencies

- `claude`
- `python3`
- Python package `httpx` for the local filter proxy transport (`python3 -m pip install httpx`)
- `curl`
- `lsof`
- `litellm` if you want the launcher to auto-start the repo-local LiteLLM on `http://127.0.0.1:4000`

## Required configuration concepts

There are three distinct configuration layers to keep straight:

### 1. LiteLLM upstream config

LiteLLM must already be running and reachable. `claudelitellm` does not start LiteLLM for you.

The launcher expects:

- upstream base URL: `REAL_LITELLM_URL` (default `http://127.0.0.1:4000`)
- auth key when required: `LITELLM_KEY`
- model name passed through Claude env: `ANTHROPIC_MODEL`

### 2. Claude merged config

The launcher creates a temporary clean `HOME`, then overlays config directories into it.

The effective config sources are:

- this repo's `.claude` and `.codex` if present
- your real `~/.claude` and `~/.codex`
- any parent `.claude` or `.codex` directories discovered while walking from `/` down to the current working directory
- any explicit `CLAUDE_CONFIG_DIR` overlay supplied at launch time

Later layers win.

This is why repo-local config can override home-level defaults even though Claude is running under a temporary home.

As a stability guard, the launcher strips merged `hooks` from the clean-home `settings.json` before Claude starts. That prevents unrelated `SessionStart` automations from your real home or parent-directory config from firing inside the isolated wrapper session.

### 3. MCP config for this wrapper

This build has a dedicated MCP config path.

Resolution order is:

1. `MCP_CONFIG_PATH` when explicitly set
2. `~/.claude/claudelitellmmcps.json`
3. repo-local `.claude/claudelitellmmcps.json` copied into the merged clean home
4. merged `CLAUDE_CONFIG_DIR/claudelitellmmcps.json` when neither direct source exists
5. no MCP config if none of those exist

The important operational detail is that this wrapper uses `claudelitellmmcps.json`, not the normal general-purpose Claude MCP registration path as its primary integration surface.

For local operator use, the usual real file is:

- `~/.claude/claudelitellmmcps.json`

`bin/bootstrap-claude-config` does this:

- if `~/.claude/claudelitellmmcps.json` already exists, it leaves it in place and reminds you that the launcher prefers it
- otherwise it seeds `~/.claude/claudelitellmmcps.json` from the checked-in example

The committed repo example is the safe template. Personal tokens should live in your home MCP config or in environment variables, not in the tracked repo-local file.

## Telegram wiring in this build

Telegram for this environment should be wired into the `claudelitellmmcps.json` file used by the launcher.

Current live path:

- MCP config file: `~/.claude/claudelitellmmcps.json`
- Telegram bridge server: `/Users/claw/openclaw/workspace/plugins/telegram/server.ts`
- Telegram state: `~/.claude/channels/telegram/.env`
- Telegram access control: `~/.claude/channels/telegram/access.json`

Example MCP entry:

```json
{
  "telegram": {
    "command": "bun",
    "args": [
      "/Users/claw/openclaw/workspace/plugins/telegram/server.ts"
    ]
  }
}
```

The Telegram bridge also has local runtime dependencies in its own directory, so if the bridge fails to start, check the plugin directory first:

- `/Users/claw/openclaw/workspace/plugins/telegram/package.json`
- `/Users/claw/openclaw/workspace/plugins/telegram/node_modules`

## Usage

```bash
bin/bootstrap-claude-config
bin/claudelitellm
```

You can also run with explicit overrides:
If `REAL_LITELLM_URL` points at the default local endpoint and nothing is listening on port `4000`, the launcher will try to start LiteLLM itself using:

- `config/litellm.env`
- `config/litellm.config.yaml`

`bin/bootstrap-claude-config` does this:

- if `~/.claude/claudelitellmmcps.json` exists, it leaves that file as the preferred source
- otherwise it seeds `~/.claude/claudelitellmmcps.json` from the checked-in example

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="..."
export SUPABASE_ACCESS_TOKEN="..."
export VERCEL_API_KEY="..."

REAL_LITELLM_URL=http://127.0.0.1:4000 \
ANTHROPIC_MODEL=claude-fable-5 \
MCP_CONFIG_PATH="$HOME/.claude/claudelitellmmcps.json" \
bin/claudelitellm
```

## Environment variables
## LiteLLM config example

The checked-in example config keeps the default `claude-fable-5` model mapping for Azure:

```yaml
model_list:
  - model_name: claude-fable-5
    litellm_params:
      model: openai/claude-fable-5
      api_base: https://blessed-abundance-resource.services.ai.azure.com/anthropic/v1/messages
      api_key: os.environ/AZURE_API_KEY
      api_version: os.environ/AZURE_API_VERSION
      timeout: 600
      stream_timeout: 600
    model_info:
      mode: chat
      supports_function_calling: true

  - model_name: glm-5.2:cloud
    litellm_params:
      model: ollama_chat/glm-5.2:cloud
      api_base: http://127.0.0.1:11434
      api_key: os.environ/OLLAMA_API_KEY
      reasoning_effort: medium
    model_info:
      supports_function_calling: true
      mode: chat

  - model_name: gpt-oss:20b:cloud
    litellm_params:
      model: ollama_chat/gpt-oss:20b:cloud
      api_base: http://127.0.0.1:11434
      api_key: os.environ/OLLAMA_API_KEY
    model_info:
      supports_function_calling: true
      mode: chat

  - model_name: qwen3-coder:30b
    litellm_params:
      model: ollama_chat/qwen3-coder:30b
      api_base: http://127.0.0.1:11434
      api_key: os.environ/OLLAMA_API_KEY
      keep_alive: 8m
    model_info:
      supports_function_calling: true

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY

litellm_settings:
  default_model_name: glm-5.2:cloud
  drop_params: true
```

Set the Ollama API key in your environment before starting LiteLLM:

```bash
export OLLAMA_API_KEY="<your-ollama-api-key>"
```

Copy `config/litellm.config.yaml.example` to `config/litellm.config.yaml` before starting the repo-local LiteLLM instance.

## LiteLLM config example

The checked-in example config keeps the default `gpt-5.4` model mapping for Azure:

```yaml
model_list:
  - model_name: claude-fable-5
    litellm_params:
      model: openai/claude-fable-5
      api_base: https://blessed-abundance-resource.services.ai.azure.com/anthropic/v1/messages
      api_key: os.environ/AZURE_API_KEY
      api_version: os.environ/AZURE_API_VERSION
      timeout: 600
      stream_timeout: 600
    model_info:
      mode: chat
      supports_function_calling: true

  - model_name: glm-5.2:cloud
    litellm_params:
      model: ollama_chat/glm-5.2:cloud
      api_base: http://127.0.0.1:11434
      api_key: os.environ/OLLAMA_API_KEY
      reasoning_effort: medium
    model_info:
      supports_function_calling: true
      mode: chat

  - model_name: gpt-oss:20b:cloud
    litellm_params:
      model: ollama_chat/gpt-oss:20b:cloud
      api_base: http://127.0.0.1:11434
      api_key: os.environ/OLLAMA_API_KEY
    model_info:
      supports_function_calling: true
      mode: chat

  - model_name: qwen3-coder:30b
    litellm_params:
      model: ollama_chat/qwen3-coder:30b
      api_base: http://127.0.0.1:11434
      api_key: os.environ/OLLAMA_API_KEY
      keep_alive: 8m
    model_info:
      supports_function_calling: true

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY

litellm_settings:
  default_model_name: glm-5.2:cloud
  drop_params: true
```

Set the Ollama API key in your environment before starting LiteLLM:

```bash
export OLLAMA_API_KEY="<your-ollama-api-key>"
```

Copy `config/litellm.config.yaml.example` to `config/litellm.config.yaml` before starting the repo-local LiteLLM instance.

## Environment

Supported variables:

- `REAL_LITELLM_URL`
- `FILTER_PORT`
- `ANTHROPIC_MODEL`
- `CLAUDE_CONFIG_DIR`
- `MCP_CONFIG_PATH`
- `LITELLM_KEY`
- `FILTER_SCRIPT_PATH`
- `FILTER_LOG_PATH`
- `LITELLM_MODELS_OUTPUT`
- `FILTER_MODELS_OUTPUT`
- `FILTER_UPSTREAM_TIMEOUT`
- `FILTER_UPSTREAM_CONNECT_TIMEOUT`
- `FILTER_UPSTREAM_RETRIES`
- `FILTER_UPSTREAM_RETRY_BACKOFF`
- `FILTER_MAX_CONNECTIONS`
- `FILTER_MAX_KEEPALIVE_CONNECTIONS`

For launcher auth, export the client key as `LITELLM_KEY` before launch if you are connecting to an already-running LiteLLM that requires auth and you do not want the launcher to prompt.

```bash
export LITELLM_KEY="<your-litellm-key>"
```

If your LiteLLM server is configured to require a master key, that server-side config is typically named `LITELLM_MASTER_KEY` in the LiteLLM process configuration.

Default behavior:

- `CLAUDE_CONFIG_DIR` defaults to this repo's `.claude` directory when present
- `MCP_CONFIG_PATH` defaults to `claudelitellmmcps.json` in the merged Claude config directory
- if that resolved MCP file is missing, the launcher continues without `--mcp-config`

## Operational notes

- The launcher creates a temporary clean `HOME` specifically so it does not reuse an existing Claude login session.
- The clean-home launch also starts from `env -i`, so inherited wrapper-mode environment from the parent Claude process is not passed through into the nested Claude session.
- `GH_CONFIG_DIR` is forwarded so GitHub auth can still work inside the clean-home session.
- Temporary artifacts are written under `/tmp` or `$TMPDIR` unless overridden, and the temp clean home is removed with Python `shutil.rmtree` to avoid noisy macOS `rm` failures on transient npm cache trees.
- The launcher now waits briefly for `FILTER_PORT` to be released before rebinding, and the embedded TCP server enables address reuse so immediate restarts do not trip over macOS socket teardown timing.
- If an already-running filter proxy is listening on `FILTER_PORT` and answers like the expected local filter, the launcher reuses it instead of trying to replace it.
- The filter proxy binds to `127.0.0.1` only by default via `FILTER_BIND_HOST`.
- The proxy now rejects unexpected `Host` headers; override the allowlist with `FILTER_ALLOWED_HOSTS` only when you intentionally need more than `127.0.0.1`, `localhost`, or the current hostname.
- Upstream forwarding now uses a reusable `httpx` client with connection pooling plus bounded retries for transient GET/HEAD/OPTIONS failures; tune it with the `FILTER_UPSTREAM_*` and `FILTER_MAX_*` variables when needed.
- Changes to proxy behavior must be made in `bin/claudelitellm` because the proxy script is generated there at runtime.
- If LiteLLM auth is missing, the launcher stops before the interactive Claude session starts.
- If MCP servers appear to be missing inside a launched session, check `MCP_CONFIG_PATH` resolution before checking standard Claude local MCP registration.

## Verification

There is no formal test suite today.

Before launch, the wrapper overlays config directories in this order:

- your real `~/.claude` and `~/.codex`
- this repo's `.claude` and `.codex` if present
- any `.claude` or `.codex` directories found while walking from `/` down to the current working directory, including this repo's `.claude` when launched from the repo

Later layers win, so project-local config can override home-level defaults.

Primary verification steps:

```bash
bash -n bin/claudelitellm
```

Then run against a reachable LiteLLM instance with valid auth when needed:

```bash
bin/claudelitellm
```

A healthy run should show all of the following:

- the upstream LiteLLM `/v1/models` endpoint returns `200`
- the local filter proxy `/v1/models` endpoint also succeeds
- Claude launches with `ANTHROPIC_BASE_URL` pointed at the filter proxy
- when configured, Claude launches with `--mcp-config` pointing at the resolved `claudelitellmmcps.json`

When debugging failures:

- inspect the configured filter log path
- confirm the LiteLLM key is valid
- confirm the resolved MCP config file exists and contains the expected server entries
- confirm bridge-specific runtimes, such as Telegram, have their own local dependencies installed

## Troubleshooting: agent descriptions overload (the getpwuid trap)

If a launched session reports `Agent descriptions are over the 15.0k-token limit (~51.3k tokens)` and starts ~90% full on context, this is the `getpwuid` trap. It looks like a launcher bug but it is not fixable from the launcher alone. Read this before spending time on it.

### Root cause

Claude Code resolves the "user" config source from the **real OS home** (`getpwuid(getuid())` -> `/Users/claw`), not from the `HOME` env var. The launcher starts Claude with `env -i HOME="$CLEAN_HOME"` and `CLAUDE_CONFIG_DIR="$MERGED"` so the nested session does not reuse an existing Claude login. But Claude Code still reads `/Users/claw/.claude/agents` (the real home) **in addition to** `$CLAUDE_CONFIG_DIR/agents`, regardless of `HOME`.

When `~/.claude/agents` is a symlink into `~/.openclaw/agents`, Claude Code follows it and loads the entire openclaw agents tree: a 2.7 GB directory containing a full nested `codex-home/`, `sessions/`, `harness-auth/`, and plugin skill caches per agent (~11,000 markdown files, 66 MB of `.md`). That is the 51.3k tokens. The launcher's clean-home overlay and `materialize_agents_dir` step only affect `$CLAUDE_CONFIG_DIR/agents`, which Claude Code ignores for the user source, so they cannot reduce this number. The same root cause is why the `SessionStart` hook (claude-mem) still ran despite the launcher stripping `hooks` from the merged `settings.json`: Claude Code reads the real `~/.claude/settings.json`.

Confirmed empirically with a debug run: under `env -i HOME=<clean-home> CLAUDE_CONFIG_DIR=<merged>`, Claude Code's debug log still referenced `/Users/claw/.claude/agents` (the openclaw symlink) plus the merged temp path. `HOME` does not redirect the user config source.

### Why the launcher-only fix cannot work

Because Claude Code reads the real home via `getpwuid`, no amount of clean-home overlay, `materialize_agents_dir`, `--setting-sources`, or `CLAUDE_CONFIG_DIR` redirection can stop `~/.claude/agents` from being loaded when it is the openclaw symlink. The detach has to happen at the real `~/.claude/agents` symlink itself.

### The actual fix (detach at the real symlink)

`~/.openclaw/agents` is openclaw's runtime. openclaw references each agent directly via `agentDir` in `~/.openclaw/openclaw.json` (e.g. `agentDir: /Users/claw/.openclaw/agents/ruby/agent`), so openclaw keeps full access to `~/.openclaw/agents` and never needs `~/.claude/agents`. The `~/.claude/agents` symlink only exists to expose openclaw agents as Claude Code subagents. Replacing it with a minimal standalone copy keeps the personas available to Claude Code while detaching the 2.7 GB runtime:

```bash
# Backup the symlink target (it is just: /Users/claw/.openclaw/agents)
readlink ~/.claude/agents > /tmp/agents-symlink-backup.txt

# Build a minimal real agents dir: AGENT.md + IDENTITY.md per agent only
tmp=$(mktemp -d /tmp/agents-min.XXXXXX)
for d in /Users/claw/.openclaw/agents/*/; do
  n=$(basename "$d"); mkdir -p "$tmp/$n/agent"
  [ -f "$d/AGENT.md" ] && cp "$d/AGENT.md" "$tmp/$n/AGENT.md"
  idf=$(find -L "$d/agent" -maxdepth 1 \( -iname "IDENTITY.md" -o -iname "identity.md" \) 2>/dev/null | head -1)
  [ -n "$idf" ] && cp "$idf" "$tmp/$n/agent/IDENTITY.md"
done

# Swap: remove the symlink, move the minimal real dir in
rm -f ~/.claude/agents
mv "$tmp" ~/.claude/agents
```

Result: `~/.claude/agents` is a real directory with ~11 files (~27 KB, ~6.9k tokens), not a symlink to a 2.7 GB tree. openclaw's `~/.openclaw/agents` is untouched. Reversible: recreate the symlink with `ln -sf ~/.openclaw/agents ~/.claude/agents`.

### Verifying

Run `claudelitellm`, then `/agents` inside the session. Expect ~6.9k tokens, the six personas (adobe, anchor, emerald, iceman, main, ruby), and no "over the 15k-token limit" warning. If it still shows ~51.3k after the swap, the persistent Claude Code daemon may have cached the old config; restart the daemon and relaunch.

### If you want zero openclaw personas in claudelitellm

Remove the directory entirely instead of materializing a minimal copy: `rm -rf ~/.claude/agents`. Claude Code then has no custom subagents. openclaw is still unaffected because it uses `~/.openclaw/agents` directly.

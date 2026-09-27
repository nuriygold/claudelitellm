# Security Policy

`claudelitellm` is a local wrapper around Claude Code and LiteLLM. It can launch shell-capable agents and MCP servers, so treat every configured MCP server and upstream provider as trusted code with access to the environment you expose.

## Safe operation

- Keep `LITELLM_KEY`, provider keys, and MCP credentials outside the repository.
- Bind the filter proxy to loopback unless you have a reviewed network policy.
- Review `MCP_CONFIG_PATH` and the merged clean-home contents before launching.
- Use a dedicated OS account or container for untrusted projects.
- Do not place private paths, tokens, or channel state in tracked configuration.

## Threat model

- Shell execution: Claude Code and MCP commands can execute local processes; use least privilege and a dedicated workspace.
- Environment leakage: only pass the variables required by the selected provider and tools.
- Proxy exposure: loopback binding and host allowlists prevent accidental LAN exposure.
- Configuration precedence: repo and explicit overlays can override user defaults; inspect them before launch.
- Upstream trust: LiteLLM and every MCP server can observe requests sent to them.

Report vulnerabilities privately to the repository owner without including credentials or personal data.

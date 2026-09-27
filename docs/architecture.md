# Architecture and trust boundaries

```mermaid
flowchart LR
  C[Claude Code] --> F[127.0.0.1 filter proxy]
  F --> L[Local LiteLLM]
  L --> U[Configured upstream model]
  H[User/repo config] --> O[Clean temporary HOME overlay]
  O --> C
  M[MCP config] --> C
```

The launcher checks LiteLLM health, starts a loopback filter, strips unsupported request fields, rewrites blocked model identifiers, creates a temporary clean home, overlays approved configuration, and launches Claude with the proxy as its API base.

The user controls the trust boundaries: the LiteLLM process, upstream model provider, MCP commands, and any shell-capable agent all receive only the credentials and filesystem scope the operator chooses to expose.

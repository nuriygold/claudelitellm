# Clean-room verification

Use a disposable shell and a local LiteLLM endpoint:

```bash
git clone <repository-url> claudelitellm-clean
cd claudelitellm-clean
cp .claude/claudelitellmmcps.example.json /tmp/claudelitellmmcps.json
REAL_LITELLM_URL=http://127.0.0.1:4000 \
MCP_CONFIG_PATH=/tmp/claudelitellmmcps.json \
FILTER_PORT=4401 \
bin/claudelitellm
```

Before launch, verify that the endpoint is local, the MCP file contains placeholders only, and `env | grep` does not reveal provider credentials. After exit, confirm the temporary clean home and filter process have been removed. The launcher performs cleanup through its exit trap; a killed host process may still require operator cleanup.

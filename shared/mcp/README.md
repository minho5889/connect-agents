# Wealth MCP tool server

The `wealth_mcp_server.py` FastMCP server exposes the "Aria" concierge's tools
(account balance, recent transactions, stock quote, branch hours, book advisor
appointment). It is the backend the Orchestration AI agent calls via an
AgentCore Gateway. See `docs/02-architecture-reference.md` §4–5 for the full
walkthrough.

## Run locally

```bash
pip install -e ".[mcp]"          # from repo root; installs the `mcp` package
python shared/mcp/wealth_mcp_server.py   # serves on http://localhost:8000/mcp
```

Smoke-test from another shell with any MCP client (lists the tools):

```python
import asyncio
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

async def main():
    async with streamablehttp_client("http://localhost:8000/mcp", {}, timeout=120,
                                      terminate_on_close=False) as (r, w, _):
        async with ClientSession(r, w) as s:
            await s.initialize()
            print(await s.list_tools())

asyncio.run(main())
```

## Deploy to Amazon Bedrock AgentCore Runtime

```bash
npm install -g @aws/agentcore        # AgentCore CLI
agentcore create --protocol MCP      # scaffolds agentcore/agentcore.json
# copy wealth_mcp_server.py into the generated project; set it as the entrypoint
agentcore deploy
# -> returns a runtime ARN:
# arn:aws:bedrock-agentcore:<region>:<acct>:runtime/wealth_mcp_server-xxxxxx
```

Then register a **Bedrock AgentCore Gateway** in front of it and add it to
Connect via **AI agent designer -> integrations -> Add integration ->
Integration type = MCP server**. The gateway Discovery URL must be:

```
https://<instance>.my.connect.aws/.well-known/openid-configuration
```

> Constraints (verified): one gateway <-> one Connect instance <-> one MCP
> server; each MCP tool invocation times out at **30 seconds**.

## Replace the stubs

Each tool returns stubbed data. Swap each body for a real backend call
(core-banking / market-data / scheduling), normally through a Lambda or a
VPC-private endpoint. Keep responses well under the 30s timeout.

"""Wealth-management MCP tool server for the 'Aria' Connect Customer concierge.

This is the concierge's "hands": each registered tool becomes callable by the
Orchestration AI agent. Built on FastMCP and designed for Amazon Bedrock
AgentCore Runtime, which expects the server on 0.0.0.0:8000/mcp.

The tool LOGIC lives in `wealth_tools.py` (no MCP dependency, so it's unit
testable); this file is just the transport layer that registers each function
with FastMCP. Deploy both files together to AgentCore Runtime.

Verified-faithful against the AWS AgentCore Runtime MCP guide:
https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html
"""

from __future__ import annotations

from mcp.server.fastmcp import FastMCP

try:  # works when imported as a package (python -m shared.mcp.wealth_mcp_server)
    from . import wealth_tools
except ImportError:  # works standalone / when AgentCore copies both files together
    import os
    import sys

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import wealth_tools

# stateless_http=True is the recommended default for simple tool servers.
mcp = FastMCP(host="0.0.0.0", stateless_http=True)

# Register exactly the allow-listed tools. mcp.tool() reads each function's
# name, docstring, and type hints to build the tool schema.
for _name, _fn in wealth_tools.EXPOSED_TOOLS.items():
    mcp.tool()(_fn)


if __name__ == "__main__":
    # Local run: serves on http://localhost:8000/mcp
    mcp.run(transport="streamable-http")

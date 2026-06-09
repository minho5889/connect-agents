"""Wealth-management MCP tool server for the 'Aria' Connect Customer concierge.

This is the concierge's "hands": each @mcp.tool() becomes a tool the
Orchestration AI agent can invoke during a conversation. Built on FastMCP and
designed to run on Amazon Bedrock AgentCore Runtime, which expects the server
on 0.0.0.0:8000/mcp (the default for official MCP SDKs).

Verified-faithful against the AWS AgentCore Runtime MCP guide:
https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html

SAFETY / COMPLIANCE NOTE
------------------------
Every tool here is read-only OR a safe, reversible booking. There is
deliberately NO place_trade / transfer_funds tool: executing financial
transactions is out of scope for a self-service agent and belongs to a
licensed human. The agent may *inform* (quote a price) but must not *advise*
(blocked by the AI Guardrail) or *transact*.

The bodies below return stubbed data. Replace each with a call to your real
backend (core banking / market data / scheduling), typically through a Lambda
or a VPC-private endpoint. Keep each call well under the 30s MCP tool timeout.
"""

from __future__ import annotations

from mcp.server.fastmcp import FastMCP

# stateless_http=True is the recommended default for simple tool servers.
# Use stateless_http=False only if you need elicitation / sampling / progress.
mcp = FastMCP(host="0.0.0.0", stateless_http=True)


@mcp.tool()
def get_account_balance(account_id: str) -> dict:
    """Return the current balance for a wealth-management account.

    Args:
        account_id: The client's internal account identifier.
    """
    # TODO: replace with a call to your core-banking API (via Lambda/VPC).
    return {"account_id": account_id, "currency": "CAD", "balance": 152_340.18}


@mcp.tool()
def list_recent_transactions(account_id: str, limit: int = 5) -> list[dict]:
    """List the most recent transactions for an account (read-only).

    Args:
        account_id: The client's internal account identifier.
        limit: Maximum number of transactions to return (default 5).
    """
    # TODO: replace with a call to your core-banking API.
    transactions = [
        {"date": "2026-06-02", "description": "Dividend - XIU", "amount": 412.55},
        {"date": "2026-06-01", "description": "Advisory fee", "amount": -85.00},
        {"date": "2026-05-28", "description": "Contribution - RRSP", "amount": 2_000.00},
    ]
    return transactions[:limit]


@mcp.tool()
def get_stock_quote(symbol: str) -> dict:
    """Return a delayed market quote for a ticker symbol (informational only).

    Quoting a price is informational. Recommending whether to buy/sell is
    investment advice and is blocked by the AI Guardrail, not by this tool.

    Args:
        symbol: The ticker symbol, e.g. "NVDA".
    """
    # TODO: replace with a call to your market-data provider.
    return {
        "symbol": symbol.upper(),
        "price": 118.42,
        "currency": "USD",
        "as_of": "2026-06-09T14:30:00Z",
        "delayed_minutes": 15,
    }


@mcp.tool()
def get_branch_hours(branch: str, date: str) -> dict:
    """Return operating hours for a branch on a given date, incl. statutory holidays.

    For richer holiday/operations content, prefer a knowledge base + grounded
    retrieval; this tool is handy for structured per-branch hours lookups.

    Args:
        branch: Branch name or ID, e.g. "King Street".
        date: ISO date, e.g. "2026-05-18" (Victoria Day).
    """
    # TODO: replace with a call to your branch-operations system.
    return {
        "branch": branch,
        "date": date,
        "is_holiday": True,
        "holiday_name": "Victoria Day",
        "status": "CLOSED",
        "next_open": "2026-05-19T09:30:00-04:00",
    }


@mcp.tool()
def book_advisor_appointment(client_id: str, topic: str, preferred_day: str) -> dict:
    """Book a meeting with a licensed advisor. A safe, reversible action.

    Does NOT execute any trade or move any funds.

    Args:
        client_id: The client's identifier.
        topic: Short description of what the client wants to discuss.
        preferred_day: ISO date the client prefers, e.g. "2026-06-12".
    """
    # TODO: replace with a call to your scheduling system.
    return {
        "confirmation_id": "APPT-7741",
        "client_id": client_id,
        "topic": topic,
        "scheduled_for": f"{preferred_day} 10:00 ET",
        "status": "BOOKED",
    }


if __name__ == "__main__":
    # Local run: serves on http://localhost:8000/mcp
    mcp.run(transport="streamable-http")

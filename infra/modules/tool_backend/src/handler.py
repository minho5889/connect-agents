"""Stub Lambda backend for Aria's MCP tools.

An AgentCore Gateway target turns this Lambda into MCP tools the Orchestration
AI agent can call. Replace the stub responses with real core-banking /
market-data / scheduling calls. Keep each path well under the 30s MCP timeout.

The event shape depends on how the gateway invokes the target; this handler
branches on a `tool` field and echoes a stub result.
"""

from __future__ import annotations


def handler(event, _context):
    tool = (event or {}).get("tool", "unknown")
    args = (event or {}).get("arguments", {})

    if tool == "get_account_balance":
        return {"account_id": args.get("account_id"), "currency": "CAD", "balance": 152340.18}
    if tool == "get_stock_quote":
        return {"symbol": str(args.get("symbol", "")).upper(), "price": 118.42,
                "currency": "USD", "delayed_minutes": 15}
    if tool == "book_advisor_appointment":
        return {"confirmation_id": "APPT-7741", "status": "BOOKED"}

    return {"error": f"unknown tool: {tool}"}

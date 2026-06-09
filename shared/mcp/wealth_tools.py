"""Pure tool logic for the 'Aria' wealth-management concierge.

This module has NO MCP/transport dependency on purpose: it holds just the
business logic, so it is unit-testable without installing the `mcp` package,
and the safety contract (no trade / fund-movement tool) can be enforced in CI.

`wealth_mcp_server.py` imports these functions and registers them with FastMCP.

SAFETY / COMPLIANCE
-------------------
Every function here is read-only OR a safe, reversible booking. There is
deliberately NO place_trade / transfer_funds / buy/sell tool: a self-service
agent must never execute financial transactions. `FORBIDDEN_TOOLS` documents
that boundary and `tests/test_wealth_tools.py` asserts none leak into
`EXPOSED_TOOLS`.

The bodies return stubbed data. Replace each with a real backend call
(core banking / market data / scheduling), keeping responses well under the
30s MCP tool timeout.
"""

from __future__ import annotations


def get_account_balance(account_id: str) -> dict:
    """Return the current balance for a wealth-management account.

    Args:
        account_id: The client's internal account identifier.
    """
    return {"account_id": account_id, "currency": "CAD", "balance": 152_340.18}


def list_recent_transactions(account_id: str, limit: int = 5) -> list[dict]:
    """List the most recent transactions for an account (read-only).

    Args:
        account_id: The client's internal account identifier.
        limit: Maximum number of transactions to return (default 5).
    """
    transactions = [
        {"date": "2026-06-02", "description": "Dividend - XIU", "amount": 412.55},
        {"date": "2026-06-01", "description": "Advisory fee", "amount": -85.00},
        {"date": "2026-05-28", "description": "Contribution - RRSP", "amount": 2_000.00},
    ]
    return transactions[:limit]


def get_stock_quote(symbol: str) -> dict:
    """Return a delayed market quote for a ticker symbol (informational only).

    Quoting a price is informational. Recommending whether to buy/sell is
    investment advice and is blocked by the AI Guardrail, not by this tool.

    Args:
        symbol: The ticker symbol, e.g. "NVDA".
    """
    return {
        "symbol": symbol.upper(),
        "price": 118.42,
        "currency": "USD",
        "as_of": "2026-06-09T14:30:00Z",
        "delayed_minutes": 15,
    }


def get_branch_hours(branch: str, date: str) -> dict:
    """Return operating hours for a branch on a given date, incl. statutory holidays.

    Args:
        branch: Branch name or ID, e.g. "King Street".
        date: ISO date, e.g. "2026-05-18" (Victoria Day).
    """
    return {
        "branch": branch,
        "date": date,
        "is_holiday": True,
        "holiday_name": "Victoria Day",
        "status": "CLOSED",
        "next_open": "2026-05-19T09:30:00-04:00",
    }


def book_advisor_appointment(client_id: str, topic: str, preferred_day: str) -> dict:
    """Book a meeting with a licensed advisor. A safe, reversible action.

    Does NOT execute any trade or move any funds.

    Args:
        client_id: The client's identifier.
        topic: Short description of what the client wants to discuss.
        preferred_day: ISO date the client prefers, e.g. "2026-06-12".
    """
    return {
        "confirmation_id": "APPT-7741",
        "client_id": client_id,
        "topic": topic,
        "scheduled_for": f"{preferred_day} 10:00 ET",
        "status": "BOOKED",
    }


# The exact set of tools Aria is allowed to expose. wealth_mcp_server.py
# registers precisely these; tests assert the server matches this set.
EXPOSED_TOOLS: dict[str, callable] = {
    "get_account_balance": get_account_balance,
    "list_recent_transactions": list_recent_transactions,
    "get_stock_quote": get_stock_quote,
    "get_branch_hours": get_branch_hours,
    "book_advisor_appointment": book_advisor_appointment,
}

# Actions a self-service agent must NEVER have. Enforced by CI as a safety gate.
FORBIDDEN_TOOLS: frozenset[str] = frozenset(
    {
        "place_trade",
        "execute_trade",
        "buy_security",
        "sell_security",
        "transfer_funds",
        "wire_funds",
        "withdraw_funds",
    }
)

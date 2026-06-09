"""Contract tests for Aria's MCP tool logic — the three scenarios.

These run locally with pytest (no `mcp` runtime needed) and exercise the pure
logic in `shared/mcp/wealth_tools.py`. They mirror the Connect-side simulation
cases in `connect_simulation_cases.py`:

  1. happy_grounded     -> branch hours grounded lookup
  2. action_lookup      -> balance / transactions / quote / booking
  3. compliance_escalate-> the safety contract: no trade/transfer tool exists

The compliance test is the important CI gate: it fails the build if any
fund-moving or trade-executing tool is ever added to the server.
"""

from __future__ import annotations

import pytest

from shared.mcp import wealth_tools
from tests.connect_simulation_cases import SIMULATION_CASES


# ----- 1. Happy / grounded path -------------------------------------------------
def test_branch_hours_reports_holiday_closure():
    result = wealth_tools.get_branch_hours("King Street", "2026-05-18")
    assert result["branch"] == "King Street"
    assert result["is_holiday"] is True
    assert result["status"] == "CLOSED"
    assert result["next_open"]  # tells the caller when it reopens


# ----- 2. Action / live-data path ----------------------------------------------
def test_account_balance_shape():
    bal = wealth_tools.get_account_balance("ACCT-001")
    assert bal["account_id"] == "ACCT-001"
    assert bal["currency"] == "CAD"
    assert isinstance(bal["balance"], (int, float))


def test_recent_transactions_respects_limit():
    txns = wealth_tools.list_recent_transactions("ACCT-001", limit=2)
    assert len(txns) == 2
    assert all({"date", "description", "amount"} <= t.keys() for t in txns)


def test_stock_quote_is_informational_and_normalized():
    quote = wealth_tools.get_stock_quote("nvda")
    assert quote["symbol"] == "NVDA"  # normalized to upper-case
    assert "price" in quote
    assert quote["delayed_minutes"] >= 0  # informational, not real-time advice


def test_book_advisor_appointment_returns_confirmation():
    appt = wealth_tools.book_advisor_appointment("CLIENT-9", "portfolio review", "2026-06-12")
    assert appt["status"] == "BOOKED"
    assert appt["confirmation_id"]


# ----- 3. Compliance / safety contract -----------------------------------------
def test_no_forbidden_tool_is_exposed():
    """Aria must never be able to trade or move funds."""
    overlap = set(wealth_tools.EXPOSED_TOOLS) & wealth_tools.FORBIDDEN_TOOLS
    assert overlap == set(), f"Forbidden tool(s) exposed: {overlap}"


def test_no_forbidden_tool_is_even_defined():
    """Defense in depth: the module shouldn't define a forbidden callable either."""
    defined = {name for name in dir(wealth_tools) if callable(getattr(wealth_tools, name))}
    assert defined.isdisjoint(wealth_tools.FORBIDDEN_TOOLS)


def test_exposed_tools_are_all_callable():
    for name, fn in wealth_tools.EXPOSED_TOOLS.items():
        assert callable(fn), f"{name} is not callable"


# ----- Cross-check: spec <-> implementation ------------------------------------
def test_simulation_cases_reference_real_tools():
    """Every tool named in the Connect simulation spec exists or is a control tool."""
    control_tools = {"Complete", "Escalate"}
    for case in SIMULATION_CASES:
        expected = case["expected_tool"]
        names = expected if isinstance(expected, list) else [expected]
        for name in names:
            assert name in wealth_tools.EXPOSED_TOOLS or name in control_tools, (
                f"Case {case['id']} references unknown tool {name!r}"
            )


# ----- Optional: smoke-test that the live server imports & registers cleanly ---
def test_mcp_server_imports_and_builds():
    """Runs only when the `mcp` package is installed (skipped otherwise).

    Asserts the server module imports and constructs its FastMCP app without the
    registration loop raising. We intentionally do NOT assert the exact set of
    registered tools via FastMCP internals — that introspection API isn't pinned
    here, and asserting an unverified API would defeat the point of the test.
    """
    pytest.importorskip("mcp")
    from mcp.server.fastmcp import FastMCP

    from shared.mcp import wealth_mcp_server

    assert isinstance(wealth_mcp_server.mcp, FastMCP)

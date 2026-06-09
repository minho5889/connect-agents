# Tests

Two layers, mirroring the same three scenarios (**happy / action / compliance**).

## 1. Local contract tests (`test_wealth_tools.py`)

Run with pytest — no AWS account and no `mcp` package required (they target the
pure logic in `shared/mcp/wealth_tools.py`):

```bash
pip install -e ".[dev]"
pytest                      # or: pytest tests/test_wealth_tools.py -v
```

What they cover:
- **Happy/grounded** — `get_branch_hours` reports a holiday closure.
- **Action** — balance / transactions (limit) / quote (normalized, informational) / booking.
- **Compliance (the CI gate)** — asserts no fund-moving or trade-executing tool
  is exposed *or even defined* (`FORBIDDEN_TOOLS`). This fails the build if
  someone ever adds `place_trade`, `transfer_funds`, etc.
- A cross-check that the Connect simulation spec only names real tools.
- An optional test that the FastMCP server registers **exactly** the allow-list
  — auto-skipped unless `mcp` is installed (`pip install -e ".[mcp]"`).

## 2. Connect-side simulation spec (`connect_simulation_cases.py`)

The same three scenarios as **observe / check / actions** cases for Connect
Customer's **native testing & simulation** feature. That runtime lives *inside
Connect* (visual designer or the testing-simulation APIs) and runs against the
deployed flow + Aria agent — so this file is the **spec you build from**, not a
pytest target. See `docs/02-architecture-reference.md` §11.

Verified simulation limits: 5 concurrent tests, queue capacity 100, 5-minute
cap per test; simulated contacts can reach live agents if not terminated with
an Action block.

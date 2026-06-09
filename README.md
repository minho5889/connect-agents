# connect-agents

Research repo for building AI agents in **Amazon Connect** — a concierge agent that
routes to many specialized agents, using Amazon Connect's native AI agent capabilities.

## Layout

| Path | Purpose |
|------|---------|
| `agents/` | One directory per agent. Start with `agents/concierge/` (the router). |
| `shared/` | Shared prompts, schemas, and Python utilities used across agents. |
| `infra/` | Terraform for Amazon Connect infrastructure. |
| `infra/modules/` | Reusable Terraform modules (Connect instance, contact flows, Lambdas). |
| `infra/environments/dev/` | Per-environment root config that wires modules together. |
| `docs/` | Design notes and research findings. |
| `tests/` | Python tests (`pytest`). |

## Stack

- **Python** ≥ 3.12 (`pyproject.toml`, `boto3`; `ruff` + `pytest` for dev)
- **Terraform** for Connect infra

## Git workflow

Trunk-based: commit straight to `main` for normal iteration; use short-lived
`experiment/*` branches for risky spikes; tag known-good states with `milestone/*`.

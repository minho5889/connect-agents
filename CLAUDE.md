# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Research repo for building AI agents on **Amazon Connect** using its native AI agent
capabilities. The target design is a **concierge agent** (router) that delegates to many
specialized agents. As of this writing the repo is a scaffold: directories exist (mostly
`.gitkeep`) but agent code, shared utilities, and Terraform modules are not yet written.

## Commands

Python is managed via `pyproject.toml` (PEP 621). Install dev deps with the `dev` extra.

```bash
pip install -e ".[dev]"        # install package + pytest/ruff
pytest                          # run all tests (testpaths = tests/)
pytest tests/test_foo.py::test_bar   # run a single test
ruff check .                    # lint
ruff check --fix .              # lint + autofix
ruff format .                   # format
```

Terraform lives under `infra/`; apply per-environment from the env root, not the modules:

```bash
cd infra/environments/dev && terraform init && terraform plan
```

- Python ≥ 3.12. Ruff: line length 100, lint rules `E, F, I, UP, B`.

## Layout & architecture

- `agents/<name>/` — one directory per agent. `agents/concierge/` is the router that
  routes to the specialized agents; new agents get a sibling directory here.
- `shared/` — prompts, schemas, and Python utilities shared across agents. Cross-agent
  logic belongs here rather than being duplicated per agent.
- `infra/modules/` — reusable Terraform modules (Connect instance, contact flows, Lambdas).
- `infra/environments/dev/` — per-env root config that wires modules together; this is
  where you run Terraform.
- `docs/` — design notes and research findings.

## Git workflow

Trunk-based: commit straight to `main` for normal iteration. Use short-lived
`experiment/*` branches for risky spikes, and tag known-good states with `milestone/*`.

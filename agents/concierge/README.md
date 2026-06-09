# Concierge agent — "Aria" (wealth-management voice concierge)

Runnable scaffold for the Orchestration AI agent built in
`docs/02-architecture-reference.md`. Aria triages a wealth-management call,
answers grounded questions (branch hours), looks up account data and market
quotes via MCP tools, books advisor appointments, and escalates investment-advice
requests to a licensed human with context.

## Files

| File | What it is |
|------|------------|
| `setup_agent.py` | boto3 (`qconnect`) script: creates the AI guardrail, the Orchestration AI prompt, and the Orchestration AI agent (each + a published version). |
| `orchestration_prompt.yaml` | Aria's prompt (MESSAGES format). Note the model-specific prefill caveat in its header. |
| `escalate_tool_schema.json` | Input schema for the custom `Escalate` Return-to-Control tool. |
| `config.example.env` | Template for the env vars `setup_agent.py` reads. |

The MCP tool server Aria calls lives in [`shared/mcp/`](../../shared/mcp/README.md).

## Run

```bash
pip install -e ".[dev]"                 # boto3 (from repo root)
cp agents/concierge/config.example.env agents/concierge/.env
# edit .env: AWS_REGION, CONNECT_ASSISTANT_ID, CONNECT_INSTANCE_ARN
set -a; . ./agents/concierge/.env; set +a
python agents/concierge/setup_agent.py
```

The script prints the created `id:version` references and the **manual steps
that remain** (deploy the MCP server, attach tools in the AI agent designer, set
Aria as the default Self Service agent, build the Lex bot + contact flow, add
simulation tests).

## What's verified vs not

- **Verified-faithful** against the boto3 `qconnect` reference and the Connect
  Customer Admin Guide: `create_ai_prompt`, `create_ai_guardrail` (incl. the
  policy configs and the `CA_SOCIAL_INSURANCE_NUMBER` PII type), `create_ai_agent`
  with `orchestrationAIAgentConfiguration` (`orchestrationAIPromptId`,
  `orchestrationAIGuardrailId`, `connectInstanceArn`, `locale`).
- **Not fully verified / left to the designer**: the inner `toolConfigurations`
  (ToolConfiguration) JSON for attaching MCP/Return-to-Control tools, and the
  `create_*_version` response field for the version number (the script extracts
  `versionNumber` best-effort and tells you to inspect the response if absent).
- **Stubbed**: the MCP tool bodies in `shared/mcp/wealth_mcp_server.py` return
  fake data — replace with real backend calls.

## Compliance guardrails baked in

- **Investment advice = DENY** topic (Aria informs/quotes but never advises).
- **Contextual grounding** checks (anti-hallucination).
- **PII**: `CA_SOCIAL_INSURANCE_NUMBER` anonymized, `CREDIT_DEBIT_CARD_NUMBER`
  blocked.
- No `place_trade` / `transfer_funds` tool exists — by design.

See `docs/03-canada-compliance-regions.md` for the ca-central-1 residency and
model-availability constraints before running this against a Canadian instance.

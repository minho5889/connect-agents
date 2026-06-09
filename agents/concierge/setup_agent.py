"""Provision the 'Aria' wealth-management Orchestration AI agent in Connect Customer.

Creates, in order:
  1. An AI Guardrail (deny investment advice, contextual grounding, PII masking)
     + a published version.
  2. An Orchestration AI prompt from orchestration_prompt.yaml + a published version.
  3. An Orchestration AI agent that ties the prompt + guardrail + locale together
     + a published version.

Then prints the IDs and the manual steps that remain (attach MCP tools, set Aria
as the default Self Service agent, build the Lex bot + contact flow). Tool
attachment is intentionally left to the AI agent designer because the inner
`toolConfigurations` (ToolConfiguration) JSON is not verified here.

All `qconnect` calls and field names below are verified against the boto3
reference (CreateAIPrompt / CreateAIGuardrail / CreateAIAgent) and the Connect
Customer Administrator Guide. See docs/02-architecture-reference.md.

Usage:
    cp config.example.env .env  &&  edit .env          # fill in your values
    set -a; . ./.env; set +a                           # export the vars
    python agents/concierge/setup_agent.py

Required env: AWS_REGION, CONNECT_ASSISTANT_ID, CONNECT_INSTANCE_ARN.
Optional env: ARIA_MODEL_ID, ARIA_LOCALE, ARIA_NAME_PREFIX.
"""

from __future__ import annotations

import json
import os
import pathlib
import sys

import boto3

HERE = pathlib.Path(__file__).parent
PROMPT_YAML = (HERE / "orchestration_prompt.yaml").read_text(encoding="utf-8")


def _require(name: str) -> str:
    val = os.environ.get(name)
    if not val:
        sys.exit(f"ERROR: required environment variable {name} is not set.")
    return val


def _version_number(resource: dict) -> int:
    """Best-effort extraction of the version number from a create-*-version response.

    The create_*_version responses nest the resource (aiPrompt / aiGuardrail /
    aiAgent) and include a 'versionNumber'. If the field name differs in your
    boto3 version, inspect the printed response and qualify IDs manually as
    '<id>:<versionNumber>'.
    """
    for key in ("aiPrompt", "aiGuardrail", "aiAgent"):
        node = resource.get(key)
        if isinstance(node, dict) and "versionNumber" in node:
            return int(node["versionNumber"])
    if "versionNumber" in resource:
        return int(resource["versionNumber"])
    raise KeyError("Could not find 'versionNumber' in response; inspect it manually.")


def create_guardrail(qc, assistant_id: str, name: str) -> str:
    """Create the Aria guardrail with all policies, publish a version, return id:version."""
    resp = qc.create_ai_guardrail(
        assistantId=assistant_id,
        name=name,
        visibilityStatus="PUBLISHED",
        blockedInputMessaging=(
            "I can help with account, branch, and market-quote questions, but I "
            "can't give investment advice. Let me connect you with a licensed advisor."
        ),
        blockedOutputsMessaging=(
            "I cannot provide investment advice. I'll connect you with a licensed advisor."
        ),
        # 1) Deny investment-advice topics.
        topicPolicyConfig={
            "topicsConfig": [
                {
                    "name": "Investment Advice",
                    "definition": (
                        "Recommendations or guidance to buy, sell, or hold specific "
                        "securities, or to adopt a particular investment or portfolio "
                        "strategy."
                    ),
                    "examples": [
                        "Which stocks should I buy?",
                        "Should I move my RRSP into bonds?",
                        "Is now a good time to sell my tech holdings?",
                    ],
                    "type": "DENY",
                }
            ]
        },
        # 2) Detect hallucinations vs the knowledge source. NOTE: boto3 uses
        #    'contextualGroundingPolicyConfig' (the CLI doc sample wrote
        #    'contextualGroundPolicyConfig' -- a doc inconsistency; trust boto3).
        contextualGroundingPolicyConfig={
            "filtersConfig": [
                {"type": "GROUNDING", "threshold": 0.7},
                {"type": "RELEVANCE", "threshold": 0.5},
            ]
        },
        # 3) Mask/block sensitive data. CA_SOCIAL_INSURANCE_NUMBER and
        #    CREDIT_DEBIT_CARD_NUMBER are verified built-in PII entity types.
        sensitiveInformationPolicyConfig={
            "piiEntitiesConfig": [
                {"type": "CA_SOCIAL_INSURANCE_NUMBER", "action": "ANONYMIZE"},
                {"type": "CREDIT_DEBIT_CARD_NUMBER", "action": "BLOCK"},
            ]
        },
    )
    guardrail_id = resp["aiGuardrail"]["aiGuardrailId"]
    version = _version_number(
        qc.create_ai_guardrail_version(assistantId=assistant_id, aiGuardrailId=guardrail_id)
    )
    print(f"  guardrail: {guardrail_id}:{version}")
    return f"{guardrail_id}:{version}"


def create_prompt(qc, assistant_id: str, name: str, model_id: str) -> str:
    """Create the Orchestration prompt from YAML, publish a version, return id:version."""
    resp = qc.create_ai_prompt(
        assistantId=assistant_id,
        name=name,
        type="ORCHESTRATION",
        templateType="TEXT",
        apiFormat="MESSAGES",
        modelId=model_id,
        visibilityStatus="PUBLISHED",
        templateConfiguration={
            "textFullAIPromptEditTemplateConfiguration": {"text": PROMPT_YAML}
        },
    )
    prompt_id = resp["aiPrompt"]["aiPromptId"]
    version = _version_number(
        qc.create_ai_prompt_version(assistantId=assistant_id, aiPromptId=prompt_id)
    )
    print(f"  prompt:    {prompt_id}:{version}")
    return f"{prompt_id}:{version}"


def create_agent(
    qc, assistant_id: str, name: str, prompt_ref: str, guardrail_ref: str,
    instance_arn: str, locale: str,
) -> str:
    """Create the Orchestration AI agent, publish a version, return id:version."""
    resp = qc.create_ai_agent(
        assistantId=assistant_id,
        name=name,
        type="ORCHESTRATION",
        visibilityStatus="PUBLISHED",
        configuration={
            "orchestrationAIAgentConfiguration": {
                "orchestrationAIPromptId": prompt_ref,
                "orchestrationAIGuardrailId": guardrail_ref,
                "connectInstanceArn": instance_arn,
                "locale": locale,
                # toolConfigurations: array of ToolConfiguration. Attach MCP /
                # Return-to-Control / Constant tools in the AI agent designer
                # from your AgentCore gateway namespace -- the inner JSON shape
                # is not verified here.
            }
        },
    )
    agent_id = resp["aiAgent"]["aiAgentId"]
    version = _version_number(
        qc.create_ai_agent_version(assistantId=assistant_id, aiAgentId=agent_id)
    )
    print(f"  agent:     {agent_id}:{version}")
    return f"{agent_id}:{version}"


def main() -> None:
    region = _require("AWS_REGION")
    assistant_id = _require("CONNECT_ASSISTANT_ID")
    instance_arn = _require("CONNECT_INSTANCE_ARN")
    # Default is a us-east-1 sandbox model. For ca-central-1, valid orchestration
    # custom-prompt models are limited to (verified): us.anthropic.claude-4-5-sonnet-...,
    # global.anthropic.claude-4-5-haiku-..., global.anthropic.claude-4-5-sonnet-...,
    # or anthropic.claude-3-haiku-20240307-v1:0 (the only one that stays in-region).
    model_id = os.environ.get("ARIA_MODEL_ID", "us.anthropic.claude-4-5-haiku-20251001-v1:0")
    locale = os.environ.get("ARIA_LOCALE", "en_US")
    prefix = os.environ.get("ARIA_NAME_PREFIX", "aria")

    qc = boto3.client("qconnect", region_name=region)

    print(f"Provisioning Aria in {region} (assistant {assistant_id})...")
    guardrail_ref = create_guardrail(qc, assistant_id, f"{prefix}_guardrail")
    prompt_ref = create_prompt(qc, assistant_id, f"{prefix}_orchestration_prompt", model_id)
    agent_ref = create_agent(
        qc, assistant_id, f"{prefix}_wealth_concierge",
        prompt_ref, guardrail_ref, instance_arn, locale,
    )

    print("\nDone. Created (id:version):")
    print(json.dumps(
        {"guardrail": guardrail_ref, "prompt": prompt_ref, "agent": agent_ref}, indent=2
    ))
    print(
        "\nManual steps that remain (AI agent designer / console):\n"
        "  1. Deploy shared/mcp/wealth_mcp_server.py to AgentCore Runtime and\n"
        "     register a Bedrock AgentCore Gateway (see shared/mcp/README.md).\n"
        "  2. In the AI agent designer, open this agent and ADD its tools: the\n"
        "     gateway MCP tools + a custom 'Escalate' Return-to-Control tool\n"
        "     (use agents/concierge/escalate_tool_schema.json), plus 'Complete'.\n"
        "  3. Create a security profile scoped to those tools and assign it.\n"
        "  4. Set this agent as the default 'Self Service' AI agent.\n"
        "  5. Create a Lex bot in the Connect admin site, enable\n"
        "     AMAZON.QinConnectIntent, set Nova Sonic S2S (us-east-1/us-west-2 only).\n"
        "  6. Build the contact flow: Set voice (Generative) -> Get customer input\n"
        "     -> Check contact attributes (Lex/Session attributes/Tool) -> route\n"
        "     Complete=Disconnect, Escalate=Transfer to advisor queue with context.\n"
        "  7. Add simulation test cases (happy / action / compliance) before go-live."
    )


if __name__ == "__main__":
    main()

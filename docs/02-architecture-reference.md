# 02 — Architecture Reference: Concierge + Multi-Agent Voice on Connect Customer

> **Research deliverable 2 of 3.** How "concierge + many specialized agents" maps to Connect Customer primitives, the voice reference architecture, action-taking via MCP, human handoff, governance, and a recommended first build.
> **As of:** 2026-06-09. Post–Nov 30, 2025 native agentic path. **Sources** at bottom.

---

## 1. Mapping your mental model to Connect primitives

Your vision — *a concierge that routes to many specialized agents* — does **not** map to "many LLM agents chatting with each other." In Connect Customer it maps to:

| Your concept | Connect Customer primitive |
|---|---|
| **Concierge** (front-door triage/routing) | An **Orchestration** AI agent (from `SelfServiceOrchestrator`) reasoning over the conversation |
| **Specialized agents** (billing, fraud, card services…) | **MCP tools** + **flow modules as tools** the orchestrator selects; and/or **Return to Control** branches that route to specialist flows/queues |
| **"Take an action"** | An **MCP tool** (OOTB, flow-module, or AgentCore-Gateway-fronted custom server) |
| **Human handoff** | A **Return to Control** tool (`Escalate`, or a custom one carrying context) → contact-flow routing to a queue |
| **Per-use-case behavior** (self-service vs assist) | **Default AI agent configurations** (Self Service row, Agent Assistance row) |
| **External / non-Connect agents** | Exposed to the orchestrator as **MCP tools via AgentCore Gateway** |

> The orchestrator is the "concierge"; specialization lives in the **tool set + routing**, not in a swarm of conversational agents. True external agents plug in as MCP tools.

## 2. Voice reference architecture (self-service path)

```
PSTN/voice contact
   │
   ▼
Contact flow
   ├─ Set logging behavior
   ├─ Set voice  ──────────────►  Override speaking style = Generative
   │                              Nova Sonic-compatible voice (Matthew/Amy/Olivia/Lupe)
   ├─ Get customer input  ─────►  Conversational AI bot (Amazon Lex)
   │                              Speech model = Speech-to-Speech (Nova Sonic)
   │                              Intent enabled for Connect AI agent
   │                                   │
   │                                   ▼
   │                          Orchestration AI agent  ("the concierge")
   │                            • multi-step reasoning
   │                            • invokes MCP tools (actions / KB retrieve)
   │                            • <message>…</message> responses
   │                            • selects a Return-to-Control tool when done/blocked
   │                                   │
   ▼                                   ▼
Check contact attributes  ◄──  Lex session attributes: Tool = Complete | Escalate | <custom>
   ├─ Complete  ─────────────►  Disconnect
   ├─ Escalate  ─────────────►  Set working queue → Transfer to queue (human agent)
   └─ <custom>  ─────────────►  specialist flow / additional logic
```

Key mechanics:
- **Get customer input** invokes the **Lex-based Conversational AI bot**; the orchestrator runs behind that intent.
- When the orchestrator picks a **Return to Control** tool, the **tool name + input params land in Lex session attributes**; **Check contact attributes** (Namespace `Lex` → Session attributes → key `Tool`) routes the contact.
- For chat, enable **message streaming** for AI-powered chat.

## 3. Self-service vs agent-assist (both in scope)

- **Self-service (customer-facing):** the orchestrator path above. The AI agent talks to the caller directly.
- **Agent assist (Connect Assistant):** AI agents of type **Answer Recommendation / Manual Search / Agent assistance** surface knowledge and take actions inside the agent workspace. Critically, the AI agent **runs in the human agent's session** — tool calls are authorized against **both** the AI agent's and the human's security profile (see §6). Permission: `Connect assistant - View Access`.

## 4. Action-taking via MCP (the "do something" layer)

Three integration paths, in increasing power/effort:

1. **Out-of-the-box tools** — update contact attributes, retrieve case info, start tasks. Zero infra.
2. **Flow modules as MCP tools** — wrap existing contact-flow business logic; reuse across deterministic and generative flows. Good for logic you already maintain in Connect.
3. **Custom / third-party MCP servers** via **AgentCore Gateway**:
   - Build an MCP server (e.g., Python **FastMCP**), deploy on **Bedrock AgentCore Runtime** (containers at `0.0.0.0:8000/mcp`, stateless or stateful streamable-HTTP). No Docker/K8s to manage; `bedrock-agentcore-starter-toolkit` scaffolds it.
   - Wrap your **existing Lambda / API business logic** as agent-callable tools.
   - Register the **AgentCore Gateway** in the console with its Discovery URL; associate one gateway ↔ one Connect instance ↔ one MCP server.
   - **Stateful MCP** (Mar 2026) adds elicitation, sampling, and progress notifications via `Mcp-Session-Id` for multi-turn tool workflows.

> **Hard limit:** every MCP tool invocation must return within **30 seconds** or it's terminated. Design tools to be fast or async (kick off + poll), not long-blocking.

### Tool accuracy/control knobs (per tool)
- Add **instructions** on when/how to use the tool.
- **Override input values** to force correct execution.
- **Filter output values** to reduce noise/hallucination surface.

## 5. Human handoff with context

Replace the default `Escalate` with a **custom Return to Control tool** that captures structured context so the human starts warm. Example input schema fields used by AWS's own example: `customerIntent`, `sentiment` (positive/neutral/frustrated), `escalationSummary` (≤500 chars), `escalationReason` (enum). Then in the flow:
- **Set contact attributes** to copy those Lex session attributes into contact attributes.
- **Set event flow → Default flow for agent UI** to screen-pop the summary/reason/sentiment to the human agent on accept.

This is how the concierge "briefs" the specialist (human or another flow) instead of dumping a cold transfer.

## 6. Governance (bank-grade controls you get natively)

- **Security profiles** = the boundary of what each AI agent can do. They govern: which tools it can invoke, what data it can touch, who can configure agents/prompts/guardrails, and whether an employee may have an AI agent act on their behalf.
- **Tool ↔ permission mapping** mirrors human permissions, e.g. Cases tool ⇒ *Cases – View/Edit*; KB Retrieve ⇒ *Connect assistant – View Access*; Tasks ⇒ *Tasks – Create*.
- **Shared-permission rule (agent assist):** the human's profile must include the same permissions as the AI agent's tools, or tool calls fail.
- **AI Guardrails** (Amazon Bedrock guardrails, max 3): for an FI, the two that earn their keep are **Sensitive information filters** (block/mask PII — SSN, DOB, address + custom regex, in *both* user input and model output) and **Contextual grounding checks** (anti-hallucination vs source). Plus content filters, denied topics (≤30), word filters. ⚠️ **No image filter**; guardrail scanning **adds time-to-first-token latency** on streaming voice — apply selectively if latency-critical.
- **Model version pinning** = change control. Pin AI-prompt model versions (vs `Latest`) so a bank can validate a model before it changes in production; Connect auto-redirects only on deprecation. Note **available models differ by region** (doc 03).
- **Analytics + traces** give per-interaction tool-invocation visibility (request/response payloads) for audit/troubleshooting.

## 6b. Test before you ship: native testing & simulation

Connect's **native testing & simulation** validates self-service flows (voice + chat) before deployment — essential for change management in a regulated FI. Build test cases in a visual designer or via API as **observe / check / actions** interaction groups (assert prompts, attributes, tool selections); results show pass/fail + interaction path + logs in analytics dashboards.
- **Available in all regions Connect is offered, incl. ca-central-1.**
- **Limits:** 5 concurrent tests · queue capacity 100 · **5-min per test** · ⚠️ simulated contacts can **reach live agents** if not terminated with an Action block.
- Use it for **regression-testing the orchestrator** when you change prompts, tools, or models.

## 7. Backend patterns (where the orchestrator calls into)

Use **AWS Prescriptive Guidance — Agentic AI patterns** to design the backend the orchestrator's MCP tools reach: reasoning agents, retrieval-augmented agents, **workflow orchestrators**, and **collaborative multi-agent systems**, plus event-driven coordination, subagent delegation, and observability. Host these as MCP servers on **AgentCore Runtime**; bridge existing **Step Functions / Lambda** logic in as tools.

## 8. Recommended first build (lowest-risk, highest-learning)

Given your priorities (grounded Q&A first, voice, Canadian-bank constraints) and the **Canada voice gap** (doc 03), build in two tracks:

**Track A — Learning sandbox in `us-east-1`** (full Nova Sonic): stand up **one** Orchestration agent for a **single domain** (e.g., "card services FAQ + balance lookup"):
1. Orchestrator from `SelfServiceOrchestrator` + a tailored `SelfServiceOrchestration` prompt.
2. **One KB retrieve tool** (grounded Q&A — your phase-1 capability) + **one MCP action tool** (a balance lookup on AgentCore Runtime wrapping a stub Lambda) + default `Complete`/custom `Escalate`.
3. Lex Conversational AI bot with **Nova Sonic S2S**; contact flow with Get customer input → Check contact attributes routing.
4. A security profile scoped to exactly those two tools; one AI Guardrail.

**Track B — Compliance-real variant in `ca-central-1`:** mirror the same orchestrator/tools, but **standard voice** (no Nova Sonic in Canada yet) and resolve the **cross-region inference** question first (doc 03). This is the variant that informs the real architecture decision for the bank.

**Why this first:** it exercises the entire native spine (orchestrator → grounded Q&A → one action → escalation with context → human queue) on voice, while surfacing the Canada constraints early instead of after you've over-invested.

**Before "done":** attach one **AI Guardrail** (sensitive-info PII masking + contextual grounding), **pin the model version**, and write **2–3 simulation test cases** (happy path, escalation, tool-failure) so the orchestrator is regression-testable from day one. Model **cost** per the [Connect pricing page](https://aws.amazon.com/connect/pricing/): AI agent + Nova Sonic + guardrail + per-MCP-round-trip usage — multi-tool turns multiply both latency and spend.

## Sources
- [Use agentic self-service](https://docs.aws.amazon.com/connect/latest/adminguide/agentic-self-service.html) · [AI agent MCP tools](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-mcp-tools.html) · [Create AI agents](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-agents.html)
- [Assign security profile permissions to AI agents](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-security-profile-permissions.html) · [Create AI guardrails](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-guardrails.html) · [Connect Customer Testing and Simulation](https://docs.aws.amazon.com/connect/latest/adminguide/testing-simulation.html) · [Upgrade models for AI prompts and agents](https://docs.aws.amazon.com/connect/latest/adminguide/upgrade-models-ai-prompts-agents.html)
- [Nova Sonic Speech-to-Speech](https://docs.aws.amazon.com/connect/latest/adminguide/nova-sonic-speech-to-speech.html)
- [Integrate an MCP server with Connect Customer (AgentCore Gateway)](https://docs.aws.amazon.com/connect/latest/adminguide/3p-apps-mcp-server.html) · [Deploy MCP servers in AgentCore Runtime](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html)
- What's New: [AgentCore Runtime stateful MCP](https://aws.amazon.com/about-aws/whats-new/2026/03/amazon-bedrock-agentcore-runtime-stateful-mcp/)
- [AWS Prescriptive Guidance: Agentic AI patterns](https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-patterns/introduction.html)
- Workshop: *Building advanced, generative AI with Connect AI agents* (catalog.workshops.aws, linked from the agentic-self-service guide)

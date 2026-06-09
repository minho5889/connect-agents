# 01 — Amazon Connect Customer: Native AI Agent Landscape & Native-vs-Custom Decisions

> **Research deliverable 1 of 3.** Current-state landscape (newest-first) + a native-vs-custom decision framework.
> **As of:** 2026-06-09. **Recency filter applied:** post–Nov 30, 2025. Pre-Nov-2025 "legacy self-service" is documented as deprecated-for-new-builds.
> **Reviewed as:** Connect specialist SA + GenAI specialist SA. **Sources:** AWS Knowledge MCP (Administrator Guide + What's New + Q Connect SDK ref), listed at bottom.

---

## 0. Locked research brief (context for all 3 docs)

- **Audience:** experienced Connect builder. Fundamentals skipped.
- **Focus:** Connect's **native** AI agents (the native/custom line has moved — see §5).
- **Channel:** **voice** (chat is the cheaper/faster sibling to pilot).
- **Target system:** a **concierge** that triages and routes to **specialized AI agents**, with **human handoff**, evolving toward **action-taking**. Phase-1 capability = **grounded conversational Q&A**; action-taking is the architecture to grow into.
- **AI roles:** customer-facing **self-service** + real-time **agent assist**.
- **Hard constraint:** regions **us-east-1 + ca-central-1**, compliance = **Canadian bank / FI**. (Drives doc 03.)

## 1. Terminology reset (changed recently — get it right)

| Old term | Current term (April 2026 rename) |
|---|---|
| Amazon Connect (product) | **Amazon Connect Customer** |
| "Amazon Q in Connect" as the AI brand | **one of several configurable AI agents** — no longer the headline |
| GenAI self-service (built-in tools) | **Legacy self-service** — *"not receiving new feature updates"* |
| — (new) | **Agentic self-service** — recommended |

> ⚠️ **SA note — the brand moved but the API didn't.** The control-plane/SDK namespace is still **`qconnect` ("Q Connect")**: e.g. the Lex intent is `AMAZON.QinConnectIntent`, and the orchestrator config object is `OrchestrationAiAgentConfiguration` in the `qconnect` SDK. When you build with IaC/SDK, expect `qconnect`/`Q in Connect` identifiers even though the console says "Connect Customer AI agents." Don't let the rename confuse your Terraform/CLI.

## 2. The 2025–2026 shift (newest-first)

| Date | Launch | Why it matters |
|---|---|---|
| **Apr–May 2026** | Voice (Nova Sonic) → Seoul/Singapore/Frankfurt + Korean & 9 more locales; release-note features | Voice expansion continues — **ca-central-1 still absent** |
| **Mar 2026** | Voice → London; **testing & simulation for chat**; **AgentCore stateful MCP** | EU voice residency now possible; richer tool servers |
| **Dec 2025** | GenAI performance evaluations → 5 more languages (incl. Canada) | Post-contact QA strong in Canada |
| **Nov 30 2025** | **Agentic self-service** (Nova Sonic voice); **MCP support**; **native testing & simulation (preview)**; AI-agent analytics; enhanced agent assist; AI case summaries | The core shift: orchestrator agents that reason + act on voice/chat |
| **Oct 2025** | Open-source MCP server for AgentCore (Kiro/Claude Code/Cursor/Q CLI) | Dev-loop tooling for MCP tools |

**Takeaway:** the center of gravity moved from "Q in Connect answers questions" to **orchestrator AI agents that reason across steps and invoke MCP tools to take action**. Your action-taking goal is now *native*.

## 3. The native AI agent surface today

### 3.1 AI agents are typed, configurable resources
In the **AI agent designer** you create agents of these types: **Orchestration** (the agentic reasoner; system default `SelfServiceOrchestrator`), **Self-Service**, **Answer Recommendation**, **Manual Search**, **Agent assistance** (Connect Assistant), and **email** agents. System **default AI agents** exist per use case; custom agents **override specific defaults** while inheriting the rest. — [create-ai-agents](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-agents.html)

**An AI agent = AI prompt(s) + AI guardrail + tools + locale.** Per the `OrchestrationAiAgentConfiguration` SDK object, an orchestrator references: instance ARN, locale, **AI prompt ID (required)**, **AI guardrail ID**, and **tool configurations**. — [customize-connect-ai-agents](https://docs.aws.amazon.com/connect/latest/adminguide/customize-connect-ai-agents.html)

### 3.2 Three tiers of self-service (don't confuse them)
| Tier | What it is | Status |
|---|---|---|
| **Agentic self-service** | Orchestrator agent: multi-step reasoning, MCP tools, continuous conversation; `<message>` tags on voice; tools = MCP / Return-to-Control (`Complete`,`Escalate`,custom) / Constant | ✅ **Recommended** |
| **Native legacy self-service** | Built-in tools **`QUESTION`, `ESCALATION`, `CONVERSATION`, `COMPLETE`, `FOLLOW_UP_QUESTION`** via `AMAZON.QinConnectIntent` + Connect assistant block; returns control to flow per tool. Note: `ESCALATION` takes the **Error** branch of *Get customer input* | ⚠️ No new features; OK to read for concepts, **don't anchor new builds** |
| **Custom solution** (e.g. `aws-samples/contact-center-genai-agent`) | A hand-built Lex + Bedrock Knowledge Base RAG app you own end-to-end | Reference only — *not* a native feature, *not* "native legacy" |

> 🔧 **Correction from first draft:** the GitHub sample is a **custom** solution, **distinct from native legacy self-service**. Both differ from agentic self-service. Use the sample for *retrieval-layer ideas*, not as a target architecture.

### 3.3 Voice: Amazon Nova Sonic speech-to-speech
Per Conversational AI bot locale (Speech model → Speech-to-Speech → Nova Sonic) + a **Set voice block** with **Override speaking style → Generative** and a Nova-Sonic voice (launch set: Matthew en-US, Amy en-GB, Olivia en-AU, Lupe es-US). Connect keeps orchestration/intents/flows; Nova Sonic does expressive speech↔speech. — [nova-sonic-speech-to-speech](https://docs.aws.amazon.com/connect/latest/adminguide/nova-sonic-speech-to-speech.html)

### 3.4 Action-taking via MCP
1. **OOTB tools** (update contact attributes, retrieve case info, start tasks). 2. **Flow modules as MCP tools** (reuse Connect business logic across deterministic + generative flows). 3. **Custom/third-party** via **Bedrock AgentCore Gateway** (APIs/Lambdas → MCP tools).
> **Limits:** MCP invocation **30-sec timeout**; gateway maps **1 gateway ↔ 1 Connect instance ↔ 1 MCP server**. Per-tool controls: instructions, override-input, filter-output. — [ai-agent-mcp-tools](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-mcp-tools.html)

### 3.5 AI Guardrails (Bedrock-based — bank-critical)
Connect AI guardrails are **Amazon Bedrock guardrails**, built no-code in the designer. **Up to 3 custom guardrails.** Policies:
- **Content filters** (Hate, Insults, Sexual, Violence, Misconduct, Prompt Attack)
- **Denied topics** (up to 30)
- **Contextual grounding check** — detects/filters **hallucinations** vs source + query relevance
- **Word filters** (exact match — profanity, competitor names)
- **Sensitive information filters** — **block or mask PII** (SSN, DOB, address) + **custom regex**
- Custom **blocked message**
> ⚠️ **No image content filter** in Connect. Languages = Bedrock **classic tier**. **Streaming latency:** guardrails buffer/scan text before delivery → higher **time-to-first-token**; weigh on latency-sensitive voice. — [create-ai-guardrails](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-guardrails.html)

### 3.6 Model lifecycle & change control (often missed)
- Each **AI prompt** pins a model; an **AI agent** references **immutable prompt versions** (model baked in). Default configs can be **pinned to a version or set to `Latest`**.
- **Custom prompt → manual** model upgrade; **no-override custom agent → auto-upgrade**; **system defaults → latest** unless pinned.
- Connect **notifies on deprecation** and **auto-redirects** to a supported model post-deprecation (no outage), but AWS recommends **upgrading manually to choose + test** the replacement.
- 🚩 **Available models depend on the instance's AWS Region** — directly relevant to ca-central-1 (see doc 03). — [upgrade-models-ai-prompts-agents](https://docs.aws.amazon.com/connect/latest/adminguide/upgrade-models-ai-prompts-agents.html)

### 3.7 Test before you ship: native testing & simulation
Validate self-service flows (voice + chat) with a visual designer or APIs; results show pass/fail + interaction path + logs, surfaced in analytics dashboards. **Available in all regions where Connect is offered (incl. ca-central-1).** Model = observe/check/actions. **Limits: 5 concurrent tests, queue 100, 5-min per test; simulated contacts can reach live agents if not terminated.** — [testing-simulation](https://docs.aws.amazon.com/connect/latest/adminguide/testing-simulation.html) (covered in doc 02 §7)

## 4. Cost lens (SA habit — verify rates on the pricing page)
AI agents, Nova Sonic voice, MCP usage, and Bedrock guardrails are **usage-priced add-ons on top of Connect's per-minute/per-message base** — rates are on the [Amazon Connect pricing page](https://aws.amazon.com/connect/pricing/) (I'm not quoting figures I haven't price-verified). SA guidance: in a contact center, **human handle time dominates cost**, so deflection via self-service is usually net-positive even at premium AI rates; but guardrails + multiple MCP round-trips add latency and per-interaction cost — model both. — [cost-optimization-bp](https://docs.aws.amazon.com/connect/latest/adminguide/cost-optimization-bp.html)

## 5. Native-vs-custom decision framework

The line moved: native agentic self-service **is** the agent framework; "custom" now mostly means **the MCP tool servers + backend** (often **AgentCore Runtime**), not a hand-rolled LLM loop.

| Axis | Lean **native** | Lean **custom** (AgentCore/Bedrock behind MCP) |
|---|---|---|
| Conversation orchestration on voice/chat | ✅ orchestrator + Nova Sonic | rarely rebuild |
| Grounded Q&A (phase 1) | ✅ KB retrieve tool | only for bespoke retrieval |
| Actions in your systems | OOTB + flow-module tools | ✅ custom MCP servers wrapping Lambdas/APIs |
| Complex multi-agent / non-Connect channels | orchestrator + tools only | ✅ external agents as MCP/A2A tools |
| **Strict Canadian residency / model choice** | ⚠️ cross-region inference + region-limited models (doc 03) | ✅ pin Bedrock model + region (subject to availability) |
| Speed to first working voice agent | ✅ fastest | slower |

**Rule of thumb:** build **conversation + escalation natively**; build **actions as MCP tools you own**; reserve fully-custom agent loops for what the orchestrator can't express, or for residency/model control native managed-AI can't guarantee.

## Sources
- [ai-agent-self-service](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-self-service.html) · [agentic-self-service](https://docs.aws.amazon.com/connect/latest/adminguide/agentic-self-service.html) · [(legacy) generative-ai-powered-self-service](https://docs.aws.amazon.com/connect/latest/adminguide/generative-ai-powered-self-service.html)
- [create-ai-agents](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-agents.html) · [customize-connect-ai-agents](https://docs.aws.amazon.com/connect/latest/adminguide/customize-connect-ai-agents.html) · [create-ai-guardrails](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-guardrails.html) · [upgrade-models-ai-prompts-agents](https://docs.aws.amazon.com/connect/latest/adminguide/upgrade-models-ai-prompts-agents.html)
- [ai-agent-mcp-tools](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-mcp-tools.html) · [nova-sonic-speech-to-speech](https://docs.aws.amazon.com/connect/latest/adminguide/nova-sonic-speech-to-speech.html) · [testing-simulation](https://docs.aws.amazon.com/connect/latest/adminguide/testing-simulation.html) · [ai-in-connect](https://docs.aws.amazon.com/connect/latest/adminguide/ai-in-connect.html)
- What's New (Nov 30 2025): [agentic self-service](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-agentic-self-service/) · [MCP support](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-mcp-support/) · [testing & simulation](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-native-testing-simulation-capabilities-preview/)
- [Prescriptive Guidance: Agentic AI patterns](https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-patterns/introduction.html) · [Connect pricing](https://aws.amazon.com/connect/pricing/)

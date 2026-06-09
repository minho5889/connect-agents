# 01 — Amazon Connect Customer: Native AI Agent Landscape & Native-vs-Custom Decisions

> **Research deliverable 1 of 3.** Current-state landscape (newest-first) + a native-vs-custom decision framework.
> **As of:** 2026-06-08. **Recency filter applied:** post–Nov 30, 2025 only. Pre-Nov-2025 "legacy self-service" is treated as deprecated.
> **Sources:** AWS Knowledge MCP server (AWS Administrator Guide + What's New), listed at the bottom.

---

## 0. Locked research brief (context for all 3 docs)

- **Audience:** experienced Connect builder. Fundamentals skipped.
- **Focus:** Connect's **native** AI agents (not custom Bedrock-from-scratch — though the boundary has moved; see §4).
- **Channel:** **voice** (with chat as the easier-to-pilot sibling).
- **Target system:** a **concierge** that triages and routes to **specialized AI agents**, with **human handoff**, evolving toward **action-taking**. Phase-1 capability priority = **grounded conversational Q&A**; action-taking is the architecture to grow into.
- **AI roles:** customer-facing **self-service** + real-time **agent assist**.
- **Hard constraint:** regions **us-east-1 + ca-central-1**, compliance = **Canadian bank / financial institution**. (Drives doc 03.)

## 1. Terminology reset (this changed recently — get it right)

| Old term | Current term (as of April 2026 rename) |
|---|---|
| Amazon Connect (the product) | **Amazon Connect Customer** |
| "Amazon Q in Connect" as the AI center | Now **one of several configurable AI agents** — no longer the headline brand |
| Generative-AI self-service (KB + custom tools) | **Legacy self-service** — *"not receiving new feature updates"* |
| — (new) | **Agentic self-service** — the recommended path |

> AWS's own wording: *"This approach [legacy] is not receiving new feature updates. We recommend using agentic self-service for new implementations."* — [ai-agent-self-service](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-self-service.html)

The availability/billing catalog even lists the product as **`Amazon Connect Customer`** (alongside `Amazon Connect Contact Lens`) — the rename is real down to the API layer.

## 2. The 2025–2026 shift (newest-first timeline)

| Date | What launched | Why it matters to you |
|---|---|---|
| **Apr 2026** | Agentic voice (Nova Sonic S2S) → **Seoul, Singapore, Frankfurt** + 10 locales incl. **Korean** | Voice expansion continues — **ca-central-1 still not on the list** |
| **Mar 2026** | Agentic voice → **London**; new voices | EU residency for voice now possible; Canada still waiting |
| **Mar 2026** | **AgentCore Runtime stateful MCP** (elicitation, sampling, progress) | Richer tool servers for your orchestrator to call |
| **Dec 2025** | GenAI performance evaluations → 5 more languages (incl. Canada Central) | Post-contact QA is strong in Canada |
| **Nov 30 2025** | **Agentic self-service** w/ **Amazon Nova Sonic** expressive voice | The core: orchestrator agents that reason + act on voice/chat |
| **Nov 30 2025** | **Model Context Protocol (MCP) support** | The integration backbone for action-taking |
| **Nov 2025** | AI-agent **analytics/monitoring**; enhanced **agent assistance**; AI **case summaries** | Lifecycle coverage (self-service → assist → post-contact) |
| **Oct 2025** | Open-source MCP server for **AgentCore** (Kiro/Claude Code/Cursor/Q CLI) | Dev-loop tooling for building MCP tools |

**Takeaway:** the center of gravity moved from "Q in Connect answers questions" to **orchestrator AI agents that reason across steps and invoke MCP tools to take action** — across voice and messaging. Your action-taking goal is now a *native* capability, not a future custom build.

## 3. The native AI agent surface today

### 3.1 AI agents are typed, configurable resources
An "AI agent" in Connect Customer is a configurable resource per use case. In the **AI agent designer** you create agents of these types:
- **Orchestration** — the multi-step reasoner for agentic self-service (system default: `SelfServiceOrchestrator`).
- **Self-Service** — customer-facing.
- **Answer Recommendation** / **Manual Search** — agent-assist knowledge surfacing.
- **Agent assistance** (Connect Assistant) — real-time help in the agent workspace.
- **Email-related** agents.

System **default AI agents** exist per use case; custom agents **override specific defaults** (custom prompts, guardrails) while inheriting the rest. — [create-ai-agents](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-agents.html)

### 3.2 Agentic self-service (the heart)
Orchestrator agents **reason across multiple steps, invoke MCP tools, and maintain a continuous conversation** without bouncing back to the contact flow between steps. Three tool types:
- **MCP tools** — take backend actions (look up order, process refund, update record).
- **Return to Control** — stop and hand back to the contact flow. Defaults: `Complete`, `Escalate`. Custom ones can carry a structured input schema (e.g., escalation reason/summary/sentiment) into the flow as Lex session attributes.
- **Constant** — return a static string for testing without a backend.

> Voice agentic responses **must be wrapped in `<message>` tags** or the customer hears nothing. — [agentic-self-service](https://docs.aws.amazon.com/connect/latest/adminguide/agentic-self-service.html)

### 3.3 Voice: Amazon Nova Sonic speech-to-speech
Configured per **Conversational AI bot locale** (Speech model → Speech-to-Speech → Nova Sonic) plus a **Set voice block** with **Override speaking style → Generative** and a Nova-Sonic-compatible voice (launch set: Matthew en-US, Amy en-GB, Olivia en-AU, Lupe es-US). Connect still manages orchestration/intents/flows; Nova Sonic handles expressive speech↔speech. — [nova-sonic-speech-to-speech](https://docs.aws.amazon.com/connect/latest/adminguide/nova-sonic-speech-to-speech.html)

### 3.4 Action-taking via MCP (3 integration paths)
1. **Out-of-the-box tools** — e.g., update contact attributes, retrieve case info.
2. **Flow modules as MCP tools** — reuse the same business logic across deterministic *and* generative flows.
3. **Third-party / custom** via **Amazon Bedrock AgentCore Gateway** (turns APIs/Lambdas/services into MCP tools; registered in console with a Discovery URL).

> **Constraints:** MCP tool invocations have a **30-second timeout**; an AgentCore gateway maps **one gateway ↔ one Connect instance ↔ one MCP server**. — [ai-agent-mcp-tools](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-mcp-tools.html), [3p-apps-mcp-server](https://docs.aws.amazon.com/connect/latest/adminguide/3p-apps-mcp-server.html)

### 3.5 Governance (native)
- **Security profiles** govern which tools an AI agent can invoke and what data it can access — the *same* framework as human agents. For agent-assist, the AI agent runs in the human's session, so tool calls are authorized against **both** the agent's and the human's permissions.
- **AI Guardrails** are first-class designer objects (All Access permission).
- **AI agent analytics/traces** expose request/response payloads and tool invocations via API.

### 3.6 What's deprecated / to avoid in new builds
- **Legacy self-service** (KB + custom-tools-return-to-flow). Still works; no new features. Don't anchor a 2026 design on it.
- Treating "Q in Connect" as a monolithic product brand rather than a set of configurable agents.

## 4. Native-vs-custom decision framework

The native/custom line has blurred: native agentic self-service **is** an agent framework, and "custom" now mostly means **the MCP tool servers and backend** behind it (often on **AgentCore Runtime**), not a hand-rolled LLM loop in Connect.

| Decision axis | Lean **native** (in-Connect agentic) | Lean **custom** (AgentCore/Bedrock behind MCP) |
|---|---|---|
| Conversation orchestration on voice/chat | ✅ Use the orchestrator agent + Nova Sonic | Rarely worth rebuilding |
| Grounded Q&A (your phase 1) | ✅ Native KB/retrieve tool | Custom only if you need a bespoke retrieval pipeline |
| Taking actions in your systems | OOTB + flow-module tools | ✅ Custom MCP servers (AgentCore Runtime) wrapping your Lambdas/APIs |
| Complex multi-agent reasoning / non-Connect channels | Limited to orchestrator + tools | ✅ Custom agents exposed as MCP/A2A tools |
| Strict Canadian data residency | ⚠️ Cross-region inference may leave Canada (doc 03) | ✅ You can pin Bedrock model + region (subject to model availability) |
| Speed to first working voice agent | ✅ Fastest | Slower |

**Rule of thumb:** build the **conversation + escalation natively**; build the **actions as MCP tools you own** (AgentCore Runtime) so the same logic is reusable and portable. Reserve fully-custom agent loops for needs Connect's orchestrator can't express, or for residency control native managed-AI can't guarantee (doc 03).

## 5. Honest caveats
- **Voice in Canada is the gap** — see doc 03. Much of "agentic self-service" *logic* is available in ca-central-1, but the **expressive Nova Sonic voice is not (yet)**.
- The widely-cited GitHub sample [`aws-samples/contact-center-genai-agent`](https://github.com/aws-samples/contact-center-genai-agent) (Lex + Bedrock KB RAG) is essentially the **legacy/custom RAG pattern**, not the new native agentic path — useful as a reference for the *retrieval* layer, not as the target architecture.

## Sources
- [Use Connect Customer AI agent self-service](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-self-service.html)
- [Use agentic self-service](https://docs.aws.amazon.com/connect/latest/adminguide/agentic-self-service.html)
- [Enable AI agents … with MCP tools](https://docs.aws.amazon.com/connect/latest/adminguide/ai-agent-mcp-tools.html)
- [Create AI agents in Connect Customer](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-agents.html)
- [Configure Amazon Nova Sonic Speech-to-Speech](https://docs.aws.amazon.com/connect/latest/adminguide/nova-sonic-speech-to-speech.html)
- [AI in Connect Customer](https://docs.aws.amazon.com/connect/latest/adminguide/ai-in-connect.html)
- What's New: [agentic self-service](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-agentic-self-service/) · [MCP support](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-mcp-support/) (both Nov 30 2025)
- [AWS Prescriptive Guidance: Agentic AI patterns and workflows](https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-patterns/introduction.html)

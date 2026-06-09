# 03 — Canada Compliance & Region Availability (ca-central-1 vs us-east-1)

> **Research deliverable 3 of 3 — the crux.** What's actually available and compliant for a **voice-first Canadian bank** on Connect Customer AI agents, and what you lose vs us-east-1.
> **As of:** 2026-06-09. **Reviewed as:** Connect specialist SA + GenAI specialist SA. **Sources** at bottom — region tables + the cross-region-inference table are primary evidence, not inference.

---

## 1. TL;DR for a Canadian FI

1. **The agentic framework works in Canada.** "Connect AI agents" (orchestration, MCP tools, self-service, agent-assist) is **listed for ca-central-1**.
2. **The premium agentic *voice* is not.** **Nova Sonic speech-to-speech** and the **Generative Voice "Set voice" block** are **not in ca-central-1**. Canadian voice = agentic *logic* + *standard* voice.
3. **Two residency problems, not one:**
   - **(a) Inference location** — a ca-central-1 instance's managed AI uses **cross-region inference that may process in `us-east-1`/`us-east-2`/`us-west-2`** (data encrypted, never stored/trained on, but **may leave Canada**).
   - **(b) Model availability** — **the set of usable models depends on the instance region**, so ca-central-1 may not offer the same/newest models as us-east-1 *even if* you stay in-region.
4. **Most everything else is in Canada:** Cases + AI summaries, full Contact Lens (GenAI summaries/categorization/evaluations), Voice ID, Customer Profiles, native testing & simulation, FIPS endpoints.

## 2. Feature availability matrix — ca-central-1 vs us-east-1

| Capability | us-east-1 | ca-central-1 | Notes |
|---|:---:|:---:|---|
| Connect Customer (core) | ✅ | ✅ | FIPS endpoint both |
| **Connect AI agents** (orchestration, MCP, self-service, assist) | ✅ | ✅ | Agentic framework is in Canada |
| **Nova Sonic agentic voice (S2S)** | ✅ | ❌ | us-east-1/us-west-2 → London → Seoul/Singapore/Frankfurt; **not Canada** |
| **Generative Voice — Set voice block** | ✅ | ❌ | Region list excludes Canada |
| Cases + **AI case summaries** | ✅ | ✅ | |
| Contact Lens (GenAI summaries/categorization/eval, real-time, theme) | ✅ | ✅ | Post-call analytics `Yes*` in Canada (verify caveat) |
| Voice ID / Customer Profiles | ✅ | ✅ | FIPS endpoints in Canada |
| **Native testing & simulation** | ✅ | ✅ | "all regions where Connect is offered" |
| Agent workspace / Tasks / Data lake / Messaging / Outbound | ✅ | ✅ | Outbound from Canada → Canadian numbers only |

> **The two ❌ rows are the whole story for voice.** Everything you need *except expressive Nova Sonic voice* is in ca-central-1.

## 3. Residency dimension (a): cross-region inference

Connect Customer's managed AI runs on **Amazon Bedrock** and uses **cross-region inference (CRIS)**. Mapping for a **ca-central-1** instance (verbatim):

| Instance region | May run inference in |
|---|---|
| **Canada (Central) `ca-central-1`** | **ca-central-1, us-east-1, us-east-2, us-west-2** |

Compare regions that **stay in-geo**: Frankfurt/London → EU only; Sydney → AU only; Tokyo → JP only. **Canada is the outlier — its mapping includes US regions.**

**Why this happens (SA context):** US-based instances use **Global CRIS** (route to *any* commercial region), while EU uses **Geographic CRIS** (stay in EU). Canada is currently bound to a North-America pool that includes the US. AWS *has* begun shipping **geo-pinned inference for sovereignty** elsewhere — e.g. SageMaker Data Agent added **Japan/Australia geo-specific inference (Mar 2026)** explicitly for regulated FS/healthcare/public-sector. **That capability does not yet exist for Connect Customer in Canada** per current docs — so it's a plausible roadmap item to push your account team on, not something to assume.

Mitigations (real, but **not** sufficient alone for a hard residency mandate): Bedrock never stores/logs/trains on data; all traffic encrypted on AWS's private network; Connect + Bedrock are in scope for many AWS compliance programs.

## 4. Residency dimension (b): region-limited models

Even staying in-region, **available models depend on the instance's AWS Region**. So:
- ca-central-1 may lack the newest/most-capable models offered in us-east-1.
- A model you validate in a us-east-1 sandbox **may not be selectable** in ca-central-1.
- Custom AI prompts pin a specific model → confirm that model is **offered in ca-central-1** before you standardize on it.

> Net: design for ca-central-1's model menu, not us-east-1's. Verify against *Supported models per Region* before committing prompts.

## 5. Compliance levers you DO get natively in Canada

| Requirement | Native control |
|---|---|
| **PII / PCI redaction** (PIPEDA, PCI-DSS) | **AI Guardrails → Sensitive information filters**: block/mask SSN, DOB, address + **custom regex**, on input *and* output. Plus Contact Lens redaction in transcripts/logs |
| **Anti-hallucination** (OSFI model risk, customer-comms accuracy) | **AI Guardrails → Contextual grounding checks** |
| **Topic/scope control** | Denied topics (≤30), word filters, content filters |
| **Access governance** (OSFI B-13) | Security profiles bound tool access per AI agent (same framework as humans) |
| **Auditability** | AI-agent traces (tool invocations, payloads); CloudTrail; analytics dashboards |
| **Crypto/in-transit** | FIPS endpoints (Connect/AppIntegrations/Profiles/Voice ID) in ca-central-1; encrypted private-network inference |
| **Pre-prod validation** (change risk) | Native testing & simulation (in ca-central-1) |

## 6. Decision guidance — three postures

| Path | Residency | AI capability | Voice |
|---|---|---|---|
| **A. Native managed AI in ca-central-1** | ⚠️ inference may go to US; region-limited models | Full agentic logic, Cases/Contact Lens GenAI | ❌ standard voice (no Nova Sonic) |
| **B. Strict Canadian residency** | ✅ in-Canada | You **own inference** (custom Bedrock in ca-central-1 behind MCP, subject to model availability); some managed features can't meet the bar | ❌ no Nova Sonic regardless |
| **C. us-east-1 for capability** | ❌ US-resident | Full incl. Nova Sonic | ✅ Nova Sonic |

For a Canadian bank with real customer data, **Path C is typically off the table for production**. Realistic posture: **A for non-residency-sensitive features + B where residency is mandated**, with a **us-east-1 sandbox (synthetic data only)** to learn the Nova Sonic voice UX.

## 7. Open questions to close with AWS (before committing the architecture)

Not answerable from public docs — take to your AWS account/SA team:
1. Can **cross-region inference be pinned to `ca-central-1`** for a Connect Customer instance (à la the JP/AU geo-specific inference), and for which features?
2. **Nova Sonic ca-central-1 ETA** — quarters or longer? (Determines whether voice parity in Canada is worth waiting for vs designing around standard voice.)
3. Exactly **which managed AI features invoke cross-region inference** vs run wholly in-region — so each feature can be classed Path A vs B.
4. **Supported-models list for ca-central-1** vs us-east-1 — and the gap's trajectory.
5. Which **compliance programs/attestations** (SOC, PCI, etc.) explicitly cover the Connect Customer AI + Bedrock data path for Canada; OSFI B-10 third-party-risk artifacts for AWS *and* any third-party MCP servers.
6. The **post-call analytics `Yes*`** caveat for Canada — exact limitation.

## 8. Bottom line

> **You can build the full agentic concierge in `ca-central-1` today — minus expressive Nova Sonic voice — but resolve BOTH residency dimensions (cross-region inference *and* region-limited models) before any real customer data flows.** Native guardrails (PII masking + contextual grounding), FIPS endpoints, security profiles, and in-region testing give you genuine compliance levers; the unresolved gap is guaranteed in-Canada *inference*. Prototype voice UX in a us-east-1 synthetic-data sandbox; make the production residency call feature-by-feature using §6's A/B split.

## Sources
- [Availability of Connect Customer features by Region](https://docs.aws.amazon.com/connect/latest/adminguide/regions.html)
- [AI in Connect Customer](https://docs.aws.amazon.com/connect/latest/adminguide/ai-in-connect.html) — Bedrock data handling, model selection, **cross-region inference table**
- [Upgrade models for AI prompts and AI agents](https://docs.aws.amazon.com/connect/latest/adminguide/upgrade-models-ai-prompts-agents.html) — *available models depend on Region*
- [Create AI guardrails](https://docs.aws.amazon.com/connect/latest/adminguide/create-ai-guardrails.html) — sensitive-info filters, contextual grounding
- [Connect Decisions: Cross-region processing](https://docs.aws.amazon.com/connect-decisions/latest/adminguide/cross-region-processing.html) — Global vs Geographic CRIS
- What's New: [SageMaker Data Agent geo-specific inference JP/AU (Mar 2026)](https://aws.amazon.com/about-aws/whats-new/2026/03/sage-maker-da-infr-jp-au/) · [Nova Sonic regions](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-agentic-self-service/)
- [AWS compliance programs / services in scope](https://aws.amazon.com/compliance/services-in-scope/)

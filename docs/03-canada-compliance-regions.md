# 03 — Canada Compliance & Region Availability (ca-central-1 vs us-east-1)

> **Research deliverable 3 of 3 — the crux.** What's actually available and compliant for a **voice-first Canadian bank** running Connect Customer AI agents, and what you lose vs us-east-1.
> **As of:** 2026-06-09. **Sources** at bottom (AWS Administrator Guide region tables + the cross-region-inference table — primary evidence, not inference).

---

## 1. TL;DR for a Canadian FI

1. **The agentic framework works in Canada.** "Connect AI agents" (orchestration, MCP tools, self-service, agent-assist) **is listed for ca-central-1**.
2. **The premium agentic *voice* is not.** **Nova Sonic speech-to-speech** and the **Generative Voice "Set voice" block** are **not available in ca-central-1**. A Canadian voice deployment gets agentic *logic* but **standard (non-Nova-Sonic) voice**.
3. **Managed-AI inference can leave Canada.** A **ca-central-1** instance's managed AI uses **cross-region inference that may process in `us-east-1`, `us-east-2`, `us-west-2`**. Data is encrypted on AWS's private network and Bedrock never stores/logs/trains on it — but it is **not guaranteed to stay in Canada**. This is the central residency tension for OSFI/PIPEDA-sensitive workloads.
4. **Most everything else is in Canada:** Cases + AI case summaries, full Contact Lens (incl. GenAI summaries/categorization/evaluations), Voice ID, Customer Profiles, FIPS endpoints.

## 2. Feature availability matrix — ca-central-1 vs us-east-1

| Capability | us-east-1 | ca-central-1 | Notes |
|---|:---:|:---:|---|
| Connect Customer (core) | ✅ | ✅ | FIPS endpoint in both |
| **Connect AI agents** (orchestration, MCP, self-service, assist) | ✅ | ✅ | The agentic framework is in Canada |
| **Nova Sonic agentic voice (S2S)** | ✅ | ❌ | Launched us-east-1/us-west-2 (Nov 30 2025); expanded to London/Seoul/Singapore/Frankfurt — **not Canada** |
| **Generative Voice — Set voice block** | ✅ | ❌ | Region list excludes Canada (Central) |
| Cases + **AI case summaries** | ✅ | ✅ | |
| Contact Lens conversational analytics | ✅ | ✅ | |
| GenAI categorization / post-contact summaries | ✅ | ✅ | |
| Performance evaluations + **GenAI** evaluations | ✅ | ✅ | |
| Real-time call analytics | ✅ | ✅ | |
| Post-call analytics | ✅ | ✅* | Canada carries a documented caveat footnote (`Yes*`) — verify specifics |
| Voice ID | ✅ | ✅ | FIPS endpoint in Canada |
| Customer Profiles (+ calculated attributes API) | ✅ | ✅ | FIPS endpoints in Canada |
| Agent workspace + step-by-step guides | ✅ | ✅ | |
| Messaging (Apple/SMS/WhatsApp/Push) | ✅ | ✅ | |
| Tasks / Data lake / Outbound campaigns | ✅ | ✅ | |
| Voice ID, FIPS endpoints (Connect/AppIntegrations/Profiles/VoiceID) | ✅ | ✅ | Relevant for FedRAMP-style hardening |

> **The two ❌ rows are the whole story for a voice-first build.** Everything you need *except expressive Nova Sonic voice* is available in ca-central-1.

## 3. The data-residency reality (cross-region inference)

Connect Customer's managed AI features run on **Amazon Bedrock** and may use **cross-region inference** to pick an "optimal" region. The mapping for a **ca-central-1** instance (verbatim from AWS docs):

| Connect Customer instance region | May run inference in |
|---|---|
| **Canada (Central) `ca-central-1`** | **ca-central-1, us-east-1 (N. Virginia), us-east-2 (Ohio), us-west-2 (Oregon)** |

Contrast with regions that **stay in-geo**:

| Instance region | Inference regions | In-geo? |
|---|---|---|
| Frankfurt / London | EU regions only | ✅ stays in EU |
| Sydney | Sydney + Melbourne | ✅ stays in AU |
| Tokyo | Tokyo + Osaka | ✅ stays in JP |
| **Canada (Central)** | **Canada + 3 US regions** | ❌ **may leave Canada (to US)** |

**Implication:** unlike EU/AU/JP deployments, a Canadian Connect Customer instance using **managed** AI features **cannot guarantee Canadian-only data processing** — inference may be served from US regions. Mitigating facts (do not, by themselves, satisfy a strict data-residency mandate):
- Bedrock **never stores, logs, or trains on** prompts/responses.
- All inference traffic is **encrypted over Amazon's private network** (not the public internet).
- Connect Customer + Bedrock are **in scope for many AWS compliance programs**.

## 4. What this means for the bank (decision guidance)

The core trade-off:

| Path | Residency | AI capability | Voice |
|---|---|---|---|
| **A. Native managed AI in ca-central-1** | ⚠️ inference may go to US | Full agentic logic, Cases/Contact Lens GenAI | ❌ no Nova Sonic (standard voice only) |
| **B. Strict Canadian residency** | ✅ in-Canada | You must **own the inference** (custom Bedrock in ca-central-1, subject to model availability) behind MCP tools; some managed Connect AI features can't meet the bar | ❌ no Nova Sonic regardless |
| **C. us-east-1 for capability, accept US data** | ❌ US-resident | Full incl. Nova Sonic | ✅ Nova Sonic |

For a Canadian bank, **Path C is typically off the table** for production customer data. The realistic posture is **A for non-residency-sensitive features + B where residency is mandated**, with a **us-east-1 sandbox** purely for learning the voice experience (no real customer data).

### Other Canada-specific constraints
- **Outbound campaigns** from a Canada (Central) instance can **only call Canadian phone numbers**.
- **FIPS endpoints** are available in ca-central-1 for Connect, AppIntegrations, Customer Profiles, and Voice ID — use them.
- **Compliance regimes to map** (your stated context): **OSFI B-13** (technology/cyber risk) and **B-10** (third-party risk — AWS + any third-party MCP servers), **PIPEDA** + provincial privacy, **PCI-DSS** for any card data over voice (DTMF masking / redaction), and PII redaction in Contact Lens transcripts/logs.

## 5. Open questions to close with AWS (before committing the architecture)

These are not answerable from public docs and should go to your AWS account/solutions team:
1. **Can cross-region inference be restricted to `ca-central-1` only** for a Connect Customer instance (or via a private/managed arrangement), and if so for which features?
2. **Nova Sonic in ca-central-1** — is it on the roadmap, and what's the ETA? (Affects whether voice quality parity in Canada is months or quarters away.)
3. Which specific managed AI features **invoke cross-region inference** vs run wholly in-region (so you can classify each feature as Path A vs B).
4. OSFI/PIPEDA attestation: which **compliance programs** explicitly cover the Connect Customer AI agent + Bedrock data path for Canada.
5. The **post-call analytics `Yes*` caveat** for Canada — what's the exact limitation.

## 6. Bottom line

> **You can build the full agentic concierge in `ca-central-1` today — minus expressive Nova Sonic voice — but you must resolve cross-region inference before any real customer data flows, because managed AI inference may be processed in the US.** Prototype voice UX in a `us-east-1` sandbox (synthetic data only); make the production residency decision feature-by-feature using §4's A/B split.

## Sources
- [Availability of Connect Customer features by Region](https://docs.aws.amazon.com/connect/latest/adminguide/regions.html) — feature region lists incl. Connect AI agents, Generative Voice, Contact Lens features, Voice ID, outbound calling
- [AI in Connect Customer](https://docs.aws.amazon.com/connect/latest/adminguide/ai-in-connect.html) — Bedrock data handling, model selection, **cross-region inference table**
- What's New: [agentic self-service / Nova Sonic regions](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-connect-agentic-self-service/) · [voice expansion to Seoul/Singapore/Frankfurt + Korean (Apr 2026)](https://aws.amazon.com/about-aws/whats-new/2026/04/amazon-connect-aws/) · [voice expansion to London (Mar 2026)](https://aws.amazon.com/about-aws/whats-new/2026/03/amazon-connect-london-europe-region/)
- [AWS compliance programs / services in scope](https://aws.amazon.com/compliance/services-in-scope/)

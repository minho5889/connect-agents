# infra/ — Terraform for the Aria concierge

Terraform that stands up the AWS infrastructure for the wealth-management voice
concierge built in `docs/02-architecture-reference.md`. Trunk-based, per-env
roots under `environments/`, reusable modules under `modules/`.

## The infra-vs-app split (why some things aren't Terraform)

| Layer | Owned by | Why |
|-------|----------|-----|
| Connect instance, S3/recordings, IAM, Lambda tool backends, AgentCore gateway | **Terraform** (`hashicorp/aws` + `hashicorp/awscc`) | Stable infrastructure; long-lived. |
| AI **agent / prompt / guardrail** (the conversational config) | **`agents/concierge/setup_agent.py`** (boto3 `qconnect`) | Iterates fast; the YAML prompt + guardrail policies are awkward in HCL and change often. |

Both paths are real. The AI-agent resources also exist as IaC if you prefer it
later — verified CloudFormation types `AWS::Wisdom::AIAgent` / `AIPrompt` /
`AIGuardrail` / `Assistant` (surfaced as `awscc_wisdom_*`) and
`AWS::BedrockAgentCore::Runtime` / `Gateway` (as `awscc_bedrockagentcore_*`).

## Layout

```
infra/
├── modules/
│   ├── connect_foundation/   # aws_connect_instance + S3 recordings + security profile
│   ├── tool_backend/         # IAM + Lambda (Aria's MCP tool backend, real handler)
│   └── agentcore_gateway/    # awscc AgentCore gateway + target (attrs flagged # VERIFY)
└── environments/
    └── dev/                  # wires the modules; run terraform here
```

## Quick start

```bash
cd infra/environments/dev
cp terraform.tfvars.example terraform.tfvars   # unique instance_alias + bucket
terraform init && terraform plan
```

Set up a **remote backend** (S3 + DynamoDB lock) before real use — the block is
stubbed in `environments/dev/providers.tf`. See that env's README for the full
apply + `setup_agent.py` handoff.

## Fidelity notes

- `connect_foundation` and `tool_backend` use well-established `hashicorp/aws`
  resources written in full.
- `agentcore_gateway` uses **verified resource types** but leaves the exact
  nested authorizer/target schema commented with `# VERIFY` — confirm against
  `terraform providers schema -json` before enabling it in `dev/main.tf`. This
  is deliberate: better an honest skeleton than guessed nested arguments.
- Provider version pins (`aws ~> 5.60`, `awscc ~> 1.0`) are starting points;
  bump to the latest your environment resolves.

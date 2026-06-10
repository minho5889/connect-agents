# dev environment

Wires the infra modules for the Aria concierge. Run Terraform from **this**
directory (not the modules).

```bash
cd infra/environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in unique names
terraform init
terraform plan
terraform apply
```

## What this provisions (verified `hashicorp/aws`)

- `module.connect_foundation` — the Connect Customer instance, an encrypted
  private S3 bucket + call-recording storage config, and an AI-agent security
  profile (permission strings flagged to confirm).
- `module.tool_backend` — IAM role + a Python 3.12 Lambda (stub handler) that
  becomes Aria's MCP tool backend.

## What's intentionally NOT here

- `module.agentcore_gateway` is **commented out** in `main.tf` so a first
  `plan` succeeds on the verified foundation. Enable it after completing the
  `# VERIFY` attributes — see `../../modules/agentcore_gateway/README.md`.
- The **AI agent / prompt / guardrail** are provisioned by the verified boto3
  script, not Terraform (infra-vs-app split — see `../../README.md`). After
  `apply`, feed the outputs into it:

  ```bash
  export CONNECT_INSTANCE_ARN=$(terraform output -raw connect_instance_arn)
  # set CONNECT_ASSISTANT_ID (aws qconnect list-assistants), then:
  python ../../../agents/concierge/setup_agent.py
  ```

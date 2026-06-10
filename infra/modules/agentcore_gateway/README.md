# Module: agentcore_gateway

Provisions a Bedrock AgentCore Gateway that exposes the tool-backend Lambda to
the Connect "Aria" agent as MCP tools.

## Verified vs. to-verify

**Verified** (these resource types exist as of 2026-06):
- CloudFormation `AWS::BedrockAgentCore::Gateway` / `AWS::BedrockAgentCore::GatewayTarget`
- Terraform: `awscc_bedrockagentcore_gateway` (+ `_gateway_target`), and native
  `aws_bedrockagentcore_gateway` / `aws_bedrockagentcore_gateway_target`.
- The Connect Discovery URL format: `https://<instance>.my.connect.aws/.well-known/openid-configuration`.
- Constraint: one gateway ↔ one Connect instance ↔ one MCP server.

**To verify before `apply`** (flagged `# VERIFY` in `main.tf`): the exact
argument schema — `protocol_type`, `role_arn`, `authorizer_type` /
`authorizer_configuration`, and the `target_configuration` (Lambda + tool
schema) nesting. Pull the live schema with:

```bash
terraform providers schema -json \
  | jq '.provider_schemas[].resource_schemas.awscc_bedrockagentcore_gateway'
```

I deliberately left those as commented skeletons rather than guess the nested
shapes — completing them against the live provider schema keeps this
verified-faithful.

## After apply

Register the gateway in Connect: **AI agent designer → integrations → Add
integration → Integration type = MCP server**, select this gateway, and set its
Discovery URL. Then attach its tools to the Aria agent in the AI agent designer.

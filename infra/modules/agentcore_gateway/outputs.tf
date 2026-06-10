output "gateway_id" {
  description = "AgentCore gateway identifier (register this in Connect: AI agent designer > integrations)."
  value       = awscc_bedrockagentcore_gateway.this.id
}

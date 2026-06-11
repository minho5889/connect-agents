output "gateway_id" {
  description = "AgentCore gateway identifier."
  value       = awscc_bedrockagentcore_gateway.this.gateway_identifier
}

output "gateway_url" {
  description = "Gateway MCP endpoint URL — register this in Connect AI agent designer > Integrations > Add MCP server."
  value       = awscc_bedrockagentcore_gateway.this.gateway_url
}

output "gateway_arn" {
  description = "Full ARN of the AgentCore Gateway."
  value       = awscc_bedrockagentcore_gateway.this.gateway_arn
}

output "connect_instance_id" {
  description = "Connect instance ID."
  value       = module.connect_foundation.instance_id
}

output "connect_instance_arn" {
  description = "Connect instance ARN — set as CONNECT_INSTANCE_ARN for agents/concierge/setup_agent.py."
  value       = module.connect_foundation.instance_arn
}

output "tool_backend_lambda_arn" {
  description = "Tool-backend Lambda ARN — use as the AgentCore gateway target."
  value       = module.tool_backend.lambda_arn
}

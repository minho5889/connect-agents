variable "name_prefix" {
  description = "Prefix for named resources (e.g. 'aria-dev')."
  type        = string
}

variable "tool_lambda_arn" {
  description = "ARN of the tool-backend Lambda to expose as MCP tools."
  type        = string
}

variable "connect_discovery_url" {
  description = "Connect instance OIDC discovery URL: https://<instance>.my.connect.aws/.well-known/openid-configuration"
  type        = string
}

variable "gateway_role_arn" {
  description = "Execution role ARN for the AgentCore gateway. VERIFY requirement."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix for named resources (e.g. 'aria-dev')."
  type        = string
}

variable "tool_lambda_arn" {
  description = "ARN of the tool-backend Lambda; gateway IAM policy allows invoking it."
  type        = string
}

variable "connect_discovery_url" {
  description = "Connect OIDC URL for production JWT auth: https://<instance>.my.connect.aws/.well-known/openid-configuration. Unused in dev (authorizer_type=NONE)."
  type        = string
  default     = ""
}

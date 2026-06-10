# AgentCore Gateway that exposes the tool-backend Lambda to Connect as MCP tools.
#
# Resource TYPES are verified (CloudFormation -> awscc):
#   AWS::BedrockAgentCore::Gateway        -> awscc_bedrockagentcore_gateway
#   AWS::BedrockAgentCore::GatewayTarget  -> awscc_bedrockagentcore_gateway_target
#   (native aws_bedrockagentcore_gateway / _gateway_target also exist)
#
# ATTRIBUTE names below are partially flagged `# VERIFY`: confirm the exact
# argument schema before apply with:
#   terraform providers schema -json | jq '.provider_schemas[].resource_schemas.awscc_bedrockagentcore_gateway'
# (CFN props seen: Name, Description, AuthorizerType, AuthorizerConfiguration,
#  RoleArn, ProtocolType, KmsKeyArn, ExceptionLevel, InterceptorConfigurations.)

resource "awscc_bedrockagentcore_gateway" "this" {
  name        = "${var.name_prefix}-aria-gateway"
  description = "Exposes wealth-management tool Lambdas to Connect Aria as MCP tools."

  # protocol_type = "MCP"        # VERIFY
  # role_arn      = var.gateway_role_arn  # VERIFY (gateway execution role)

  # The gateway must trust the Connect instance's OIDC discovery endpoint.
  # Verified Discovery URL format (Connect docs):
  #   https://<instance>.my.connect.aws/.well-known/openid-configuration
  # authorizer_type = "CUSTOM_JWT"   # VERIFY
  # authorizer_configuration = {     # VERIFY exact nested schema
  #   custom_jwt_authorizer = {
  #     discovery_url = var.connect_discovery_url
  #   }
  # }
}

# A target turns the tool-backend Lambda into MCP tools on the gateway.
resource "awscc_bedrockagentcore_gateway_target" "tools" {
  # VERIFY argument names against the provider schema before apply.
  # gateway_identifier = awscc_bedrockagentcore_gateway.this.gateway_identifier
  name        = "${var.name_prefix}-wealth-tools"
  description = "Wealth-management tool backend (balance, quote, booking)."

  # target_configuration = {        # VERIFY nested schema
  #   mcp = {
  #     lambda = {
  #       lambda_arn = var.tool_lambda_arn
  #       # tool_schema describing each tool's input/output
  #     }
  #   }
  # }
}

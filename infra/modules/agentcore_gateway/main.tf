# AgentCore Gateway that exposes the wealth MCP tools to Connect AI agents.
#
# All attributes verified against awscc provider v1.88.0 via Terraform MCP server.
# Required: authorizer_type, name, role_arn.
#
# NOTE: awscc_bedrockagentcore_gateway_target does NOT exist in the provider.
# Tool registration (linking this gateway to an AgentCore Runtime) is done via:
#   agentcore deploy (shared/mcp/deploy.sh) — the CLI registers the runtime ARN
#   with the gateway during deployment, or via the Connect AI agent designer
#   under Integrations → Add MCP server using the gateway_url output.

resource "aws_iam_role" "gateway" {
  name = "${var.name_prefix}-agentcore-gateway"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock-agentcore.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "gateway" {
  role = aws_iam_role.gateway.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = var.tool_lambda_arn
      }
    ]
  })
}

resource "awscc_bedrockagentcore_gateway" "this" {
  name          = "${var.name_prefix}-aria-gateway"
  description   = "Exposes wealth-management MCP tools to the Connect Aria AI agent."
  role_arn      = aws_iam_role.gateway.arn
  # protocol_type defaults to MCP (omitting avoids awscc JSON-string encoding quirk).

  # Dev: no auth. Production Connect integration: switch to CUSTOM_JWT and
  # add authorizer_configuration.custom_jwt_authorizer.discovery_url pointing
  # to: https://<instance>.my.connect.aws/.well-known/openid-configuration
  authorizer_type = "NONE"

  protocol_configuration = {
    mcp = {
      instructions = "Wealth-management tools: account balance, transactions, stock quotes, branch hours, advisor booking."
    }
  }

  tags = {
    Project = var.name_prefix
  }
}

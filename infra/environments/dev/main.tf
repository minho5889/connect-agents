# Dev environment — wires the modules together.
# Run from this directory: terraform init && terraform plan

module "connect_foundation" {
  source = "../../modules/connect_foundation"

  name_prefix            = var.name_prefix
  instance_alias         = var.instance_alias
  recordings_bucket_name = var.recordings_bucket_name
}

module "tool_backend" {
  source = "../../modules/tool_backend"

  name_prefix = var.name_prefix
}

# AgentCore gateway that exposes the tool Lambda to Connect as MCP tools.
# Enable once you've completed the `# VERIFY` attributes in the module
# (see infra/modules/agentcore_gateway/README.md). Left commented so a first
# `terraform plan` succeeds on the verified foundation alone.
#
# module "agentcore_gateway" {
#   source = "../../modules/agentcore_gateway"
#
#   name_prefix           = var.name_prefix
#   tool_lambda_arn       = module.tool_backend.lambda_arn
#   connect_discovery_url = "https://${var.instance_alias}.my.connect.aws/.well-known/openid-configuration"
# }

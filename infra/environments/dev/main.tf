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

# Contact flow from the vendored, verified template (export-and-template
# pattern — see infra/modules/contact_flow/README.md). Proves the flow deploy
# pipeline; replace with the exported Aria flow when authored in the console.
module "welcome_flow" {
  source = "../../modules/contact_flow"

  instance_id   = module.connect_foundation.instance_id
  name          = "${var.name_prefix}-sample-welcome"
  description   = "Verified sample flow proving the template deploy pipeline."
  template_path = "${path.module}/../../modules/contact_flow/templates/sample_welcome.json.tftpl"
  template_vars = {
    welcome_message = "Thanks for calling the Aria sandbox!"
  }
}

# Lex V2 bot shell (IAM + bot). Locale/version/alias + the V2 Connect
# association are # VERIFY skeletons inside the module — complete them with
# the terraform MCP server, and note the QinConnectIntent caveat in its README.
module "lex_bot" {
  source = "../../modules/lex_bot"

  name_prefix          = var.name_prefix
  connect_instance_arn = module.connect_foundation.instance_arn
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

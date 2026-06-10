# Contact flow deployed from a vendored, templated JSON artifact.
#
# Pattern (see README): author the flow in the Connect console designer ->
# export the known-good JSON with scripts/export_flow.sh -> replace
# environment-specific ARNs with ${placeholders} -> deploy via templatefile().
# Flow JSON is a VERIFIED ARTIFACT, never hand-authored.

locals {
  rendered = templatefile(var.template_path, var.template_vars)
}

resource "aws_connect_contact_flow" "this" {
  instance_id = var.instance_id
  name        = var.name
  description = var.description
  type        = var.type

  content = local.rendered

  tags = var.tags
}

# Connect foundation: the Amazon Connect Customer instance + call-recording storage.
# Uses hashicorp/aws (well-established resources).

resource "aws_connect_instance" "this" {
  identity_management_type  = var.identity_management_type # e.g. CONNECT_MANAGED
  instance_alias            = var.instance_alias
  inbound_calls_enabled     = true
  outbound_calls_enabled    = true
  contact_lens_enabled      = true # Contact Lens analytics (available in ca-central-1)
  contact_flow_logs_enabled = true
}

# S3 bucket for call recordings (encrypted, private).
resource "aws_s3_bucket" "recordings" {
  bucket = var.recordings_bucket_name
}

resource "aws_s3_bucket_public_access_block" "recordings" {
  bucket                  = aws_s3_bucket.recordings.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Wire call recordings to the bucket.
resource "aws_connect_instance_storage_config" "recordings" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "CALL_RECORDINGS"

  storage_config {
    storage_type = "S3"
    s3_config {
      bucket_name   = aws_s3_bucket.recordings.id
      bucket_prefix = "call-recordings"
    }
  }
}

# Security profile for the AI agent + the humans who use agent-assist.
# NOTE: exact permission strings for AI agent designer / Connect assistant vary
# by release. Confirm against your instance (Users > Security profiles) and
# docs/02-architecture-reference.md §10 before relying on this list.
resource "aws_connect_security_profile" "ai_agent" {
  name        = "${var.name_prefix}-ai-agent"
  instance_id = aws_connect_instance.this.id
  description = "Grants AI agent designer + Connect assistant access for Aria."

  # permissions = [        # VERIFY exact permission identifiers for your release
  #   "AIAgents.All",
  #   "AIPrompts.All",
  #   "AIGuardrails.All",
  # ]
}

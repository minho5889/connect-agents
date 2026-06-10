# Lex V2 bot for the Aria concierge + association with the Connect instance.
#
# VERIFIED:
# - aws_lexv2models_bot args (name, role_arn, data_privacy, idle_session_ttl_in_seconds, type).
# - aws_connect_bot_association supports Lex V1 ONLY -> V2 association goes via
#   AWS::Connect::IntegrationAssociation (CFN docs show an explicit Lex V2
#   example: IntegrationType=LEX_BOT, IntegrationArn=<bot alias ARN>), surfaced
#   in Terraform as the awscc integration-association resource.
#
# NOT YET VERIFIED (complete with the terraform MCP server, post-restart):
# - aws_lexv2models_bot_locale / _bot_version / alias resource shapes — left as
#   skeletons below rather than guessed.

# IAM role the bot runs as.
resource "aws_iam_role" "lex" {
  name = "${var.name_prefix}-lex-bot"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lexv2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lex" {
  role       = aws_iam_role.lex.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLexFullAccess" # tighten for prod
}

resource "aws_lexv2models_bot" "this" {
  name        = "${var.name_prefix}-aria-bot"
  description = "Conversational AI bot fronting the Aria orchestration agent."
  role_arn    = aws_iam_role.lex.arn
  type        = "Bot"

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300
}

# --- Locale + version + alias -------------------------------------------------
# VERIFY shapes with the terraform MCP server before enabling. Skeletons only:
#
# resource "aws_lexv2models_bot_locale" "en_us" {
#   bot_id      = aws_lexv2models_bot.this.id
#   bot_version = "DRAFT"
#   locale_id   = "en_US"
#   # n_lu_intent_confidence_threshold = 0.7   # VERIFY argument name
#   # voice_settings { ... }                   # VERIFY (Nova Sonic config may be console-only)
# }
#
# resource "aws_lexv2models_bot_version" "v1" {
#   bot_id = aws_lexv2models_bot.this.id
#   # locale_specification = { "en_US" = { source_bot_version = "DRAFT" } }  # VERIFY
# }
#
# Alias: no aws_lexv2models_* alias resource confirmed; CFN AWS::Lex::BotAlias
# exists -> awscc_lex_bot_alias. VERIFY its schema, then feed its ARN below.

# --- Associate the V2 bot with the Connect instance ----------------------------
# CFN AWS::Connect::IntegrationAssociation props (verified): InstanceId
# (instance ARN), IntegrationType=LEX_BOT, IntegrationArn (V2 bot ALIAS ARN).
# Enable once the alias above exists.
#
# resource "awscc_connect_integration_association" "lex_v2" {
#   instance_id      = var.connect_instance_arn
#   integration_type = "LEX_BOT"
#   integration_arn  = var.bot_alias_arn # the V2 bot alias ARN
# }

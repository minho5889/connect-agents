output "bot_id" {
  description = "Lex V2 bot ID."
  value       = aws_lexv2models_bot.this.id
}

output "bot_role_arn" {
  description = "IAM role the bot runs as."
  value       = aws_iam_role.lex.arn
}

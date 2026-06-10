output "lambda_arn" {
  description = "ARN of the tool-backend Lambda (use as an AgentCore Gateway target)."
  value       = aws_lambda_function.tools.arn
}

output "lambda_name" {
  description = "Name of the tool-backend Lambda."
  value       = aws_lambda_function.tools.function_name
}

output "instance_id" {
  description = "Amazon Connect instance ID."
  value       = aws_connect_instance.this.id
}

output "instance_arn" {
  description = "Amazon Connect instance ARN (pass to setup_agent.py CONNECT_INSTANCE_ARN)."
  value       = aws_connect_instance.this.arn
}

output "security_profile_id" {
  description = "AI agent security profile ID."
  value       = aws_connect_security_profile.ai_agent.id
}

output "recordings_bucket" {
  description = "Call-recordings S3 bucket name."
  value       = aws_s3_bucket.recordings.id
}

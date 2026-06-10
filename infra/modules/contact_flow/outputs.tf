output "contact_flow_id" {
  description = "Contact flow ID."
  value       = aws_connect_contact_flow.this.contact_flow_id
}

output "arn" {
  description = "Contact flow ARN."
  value       = aws_connect_contact_flow.this.arn
}

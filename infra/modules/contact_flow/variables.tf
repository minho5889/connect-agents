variable "instance_id" {
  description = "Amazon Connect instance ID."
  type        = string
}

variable "name" {
  description = "Contact flow name."
  type        = string
}

variable "description" {
  description = "Contact flow description."
  type        = string
  default     = ""
}

variable "type" {
  description = "Contact flow type (CONTACT_FLOW, CUSTOMER_QUEUE, AGENT_TRANSFER, ...)."
  type        = string
  default     = "CONTACT_FLOW"
}

variable "template_path" {
  description = "Path to the .json.tftpl flow template (exported from the console, ARNs replaced with placeholders)."
  type        = string
}

variable "template_vars" {
  description = "Values for the template placeholders (queue/Lex/Lambda ARNs, messages, ...)."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

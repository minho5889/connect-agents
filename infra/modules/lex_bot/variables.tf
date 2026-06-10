variable "name_prefix" {
  description = "Prefix for named resources (e.g. 'aria-dev')."
  type        = string
}

variable "connect_instance_arn" {
  description = "Connect instance ARN (used by the V2 integration association)."
  type        = string
}

variable "bot_alias_arn" {
  description = "Lex V2 bot ALIAS ARN to associate with Connect. Set once the alias resource is enabled."
  type        = string
  default     = ""
}

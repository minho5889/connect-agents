variable "name_prefix" {
  description = "Prefix for named resources (e.g. 'aria-dev')."
  type        = string
}

variable "instance_alias" {
  description = "Globally-unique alias for the Connect instance (CONNECT_MANAGED directory)."
  type        = string
}

variable "identity_management_type" {
  description = "Connect identity management type."
  type        = string
  default     = "CONNECT_MANAGED"
}

variable "recordings_bucket_name" {
  description = "Globally-unique S3 bucket name for call recordings."
  type        = string
}

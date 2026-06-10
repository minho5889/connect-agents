variable "region" {
  description = "AWS region. us-east-1 for the full-capability sandbox; ca-central-1 for the Canada-resident build (see docs/03)."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for named resources."
  type        = string
  default     = "aria-dev"
}

variable "instance_alias" {
  description = "Globally-unique Connect instance alias (also the my.connect.aws subdomain)."
  type        = string
}

variable "recordings_bucket_name" {
  description = "Globally-unique S3 bucket name for call recordings."
  type        = string
}

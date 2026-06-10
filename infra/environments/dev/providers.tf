terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    # awscc is generated from CloudFormation; it carries the AWS::Wisdom::* and
    # AWS::BedrockAgentCore::* resources used for the AI agent / gateway layer.
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }

  # Remote backend — recommended even solo (survives a laptop wipe; only sane
  # way to manage Connect resources). Create the bucket + lock table once, then
  # uncomment and run `terraform init -migrate-state`.
  #
  # backend "s3" {
  #   bucket         = "connect-agents-tfstate-<account-id>"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "connect-agents-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}

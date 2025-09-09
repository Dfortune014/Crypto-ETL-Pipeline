terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

# Shared tags for all resources in this module
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Fortune"
    ManagedBy   = "Terraform"
  }
}

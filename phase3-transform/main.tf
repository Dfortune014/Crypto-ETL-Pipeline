terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Fortune"
    ManagedBy   = "Terraform"
    Component   = "phase3-transform"
  }

  # Name helpers
  name_prefix = "${var.project}-${var.environment}"
}

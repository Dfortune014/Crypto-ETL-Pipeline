variable "project" {
  type    = string
  default = "crypto-analytics"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Athena database and workgroup to run the INSERT
variable "athena_db" {
  type    = string
  default = "crypto_data"
}

# ⚠️ Must exist already (created in Phase 2). Should point to analytics bucket.
variable "athena_workgroup" {
  type    = string
  default = "crypto-wg"
}

# SSM Parameter path that will store the SQL template content
variable "ssm_parameter_name" {
  type    = string
  default = "/crypto-analytics/sql/insert_last_hour"
}

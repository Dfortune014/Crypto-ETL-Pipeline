variable "project" {
  type    = string
  default = "crypto-analytics"
}

variable "environment" {
  type    = string
  default = "dev"
}

# Phase 1 bucket (already created)
variable "archive_bucket_name" {
  type    = string
  default = "crypto-analytics-archive-fortune"
}

# New, dedicated analytics bucket for curated Parquet + Athena results
variable "analytics_bucket_name" {
  type    = string
  default = "crypto-analytics-athena-results"
}

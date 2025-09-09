# -------------------------------
# QuickSight access to Athena results bucket
# -------------------------------

variable "account_id" {
  type = string
  # pass at apply: -var="account_id=021891597267"
}

variable "analytics_bucket_name" {
  type    = string
  default = "crypto-analytics-athena-results"
}

# If you use a custom QuickSight role, override this; otherwise default v0 is used.
variable "quicksight_role_arn" {
  type    = string
  default = ""
}

locals {
  quicksight_role_arn = var.quicksight_role_arn != "" ? var.quicksight_role_arn : "arn:aws:iam::${var.account_id}:role/service-role/aws-quicksight-service-role-v0"
}

data "aws_iam_policy_document" "qs_results_access" {
  # Bucket-level: allow QuickSight to discover bucket + region
  statement {
    sid    = "QSListAndLocation"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.quicksight_role_arn]
    }

    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.analytics_bucket_name}"]
  }

  # Object READ on analytics/ (QS via Athena needs to read Parquet data)
  statement {
    sid    = "QSReadAnalyticsData"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.quicksight_role_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.analytics_bucket_name}/analytics/*"]
  }

  # Object RW on query-results/ (Athena result files for QuickSight)
  statement {
    sid    = "QSResultsRW"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.quicksight_role_arn]
    }

    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.analytics_bucket_name}/query-results/*"]
  }
}

# IMPORTANT: Only use this if no other aws_s3_bucket_policy manages this bucket.
resource "aws_s3_bucket_policy" "qs_results_policy" {
  bucket = var.analytics_bucket_name
  policy = data.aws_iam_policy_document.qs_results_access.json
}

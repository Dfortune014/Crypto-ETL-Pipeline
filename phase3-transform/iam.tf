# =========================
# IAM for Phase 3 Lambda
# =========================

# -------- Lambda execution role --------
resource "aws_iam_role" "update_analytics_role" {
  name = "${local.name_prefix}-update-analytics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# -------- Managed policy document (FULL) --------
data "aws_iam_policy_document" "update_analytics_policy_doc" {
  # Athena control-plane
  statement {
    sid    = "AthenaQueryControl"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = ["*"]
  }

  # SSM Parameter Store (read SQL template)
  statement {
    sid       = "SSMGetParameter"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["*"] # optionally scope to the exact parameter ARN
  }

  # CloudWatch Logs
  statement {
    sid    = "LogsBasic"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  # ---------- Glue Catalog (READ) ----------
  statement {
    sid    = "GlueCatalogRead"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  # ---------- Glue Catalog (WRITE partitions) ----------
  statement {
    sid    = "GlueCatalogWritePartitions"
    effect = "Allow"
    actions = [
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:UpdatePartition",
      "glue:BatchUpdatePartition",
      "glue:UpdateTable"
    ]
    resources = ["*"]
  }

  # ---------- S3: bucket info (no prefix conditions) ----------
  statement {
    sid       = "S3InfoArchive"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = ["arn:aws:s3:::crypto-analytics-archive-fortune"]
  }

  statement {
    sid       = "S3InfoAnalytics"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = ["arn:aws:s3:::crypto-analytics-athena-results"]
  }

  # ---------- S3: read source data (processed NDJSON.gz) ----------
  statement {
    sid       = "S3ReadProcessed"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::crypto-analytics-archive-fortune/processed/*"]
  }

  # ---------- S3: write curated Parquet (analytics/) ----------
  statement {
    sid       = "S3WriteAnalytics"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::crypto-analytics-athena-results/analytics/*"]
  }

  # ---------- S3: Athena query results (query-results/) ----------
  # Keep this because your Lambda is currently using workgroup crypto-wg,
  # which writes small CSV/manifests under query-results/.
  statement {
    sid       = "S3ResultsObjects"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::crypto-analytics-athena-results/query-results/*"]
  }
}

resource "aws_iam_policy" "update_analytics_policy" {
  name   = "${local.name_prefix}-update-analytics-policy"
  policy = data.aws_iam_policy_document.update_analytics_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_update_analytics_policy" {
  role       = aws_iam_role.update_analytics_role.name
  policy_arn = aws_iam_policy.update_analytics_policy.arn
}

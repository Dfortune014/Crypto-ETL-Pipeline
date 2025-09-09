# ---------------------------
# S3 Data Lake Bucket (Phase 1)
# ---------------------------

# Shared tags (expects variables: project, environment)
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Fortune"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket
resource "aws_s3_bucket" "archive" {
  bucket = var.bucket_name
  tags   = local.common_tags
}

# Enforce bucket owner for all objects (disable ACLs)
resource "aws_s3_bucket_ownership_controls" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "archive" {
  bucket                  = aws_s3_bucket.archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Default server-side encryption (SSE-S3, AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# TLS-only bucket policy (deny insecure HTTP)
data "aws_iam_policy_document" "tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.archive.arn,
      "${aws_s3_bucket.archive.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.archive.id
  policy = data.aws_iam_policy_document.tls_only.json
}

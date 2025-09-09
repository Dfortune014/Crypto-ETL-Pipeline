# ---------------------------
# Athena Workgroup
# ---------------------------

resource "aws_athena_workgroup" "crypto" {
  name = "crypto-wg"

  configuration {
    result_configuration {
      output_location = "s3://${var.analytics_bucket_name}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
  }

  tags = local.common_tags
}

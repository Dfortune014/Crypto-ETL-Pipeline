data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/update_analytics.py"
  output_path = "${path.module}/lambda/update_analytics.zip"
}

resource "aws_lambda_function" "update_analytics" {
  function_name = "${local.name_prefix}-updateAnalyticsHourly"
  role          = aws_iam_role.update_analytics_role.arn
  runtime       = "python3.11"
  handler       = "update_analytics.lambda_handler"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 180
  memory_size   = 256

  environment {
    variables = {
      ATHENA_DB          = var.athena_db
      ATHENA_WORKGROUP   = var.athena_workgroup
      SQL_PARAMETER_NAME = var.ssm_parameter_name
    }
  }

  tags = local.common_tags
}

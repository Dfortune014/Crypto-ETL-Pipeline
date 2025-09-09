data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/fetch_prices.py"
  output_path = "${path.module}/lambda/fetch_prices.zip"
}

resource "aws_lambda_function" "fetch_prices" {
  function_name = "fetchCryptoPrices"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "fetch_prices.lambda_handler"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.archive.bucket
    }
  }

  depends_on = [
    aws_s3_bucket.archive,
    aws_iam_role.lambda_exec
  ]

  tags = local.common_tags
}

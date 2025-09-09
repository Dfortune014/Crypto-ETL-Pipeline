output "bucket" {
  value = aws_s3_bucket.archive.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.fetch_prices.function_name
}

output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.every_5_minutes.arn
}

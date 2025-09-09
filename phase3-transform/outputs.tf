output "lambda_function_name" {
  value = aws_lambda_function.update_analytics.function_name
}

output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.update_analytics_hourly.arn
}

output "athena_db" {
  value = var.athena_db
}

output "athena_workgroup" {
  value = var.athena_workgroup
}

output "ssm_parameter_name" {
  value = var.ssm_parameter_name
}

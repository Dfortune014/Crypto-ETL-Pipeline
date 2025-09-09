# Run at :05 every hour (UTC)
resource "aws_cloudwatch_event_rule" "update_analytics_hourly" {
  name                = "${local.name_prefix}-update-analytics-hourly"
  schedule_expression = "cron(5 * * * ? *)"
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "update_analytics_target" {
  rule      = aws_cloudwatch_event_rule.update_analytics_hourly.name
  target_id = "update-analytics"
  arn       = aws_lambda_function.update_analytics.arn
}

resource "aws_lambda_permission" "allow_events_invoke_update_analytics" {
  statement_id  = "AllowEventsInvokeUpdateAnalytics"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_analytics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.update_analytics_hourly.arn
}

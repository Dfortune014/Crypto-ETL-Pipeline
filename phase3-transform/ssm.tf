# Upload the SQL template to Parameter Store from local file
resource "aws_ssm_parameter" "insert_last_hour_sql" {
  name  = var.ssm_parameter_name
  type  = "String"
  value = file("${path.module}/sql/insert_last_hour.sql")

  tags = local.common_tags
}

output "glue_database" {
  value = aws_glue_catalog_database.crypto.name
}

output "processed_table" {
  value = aws_glue_catalog_table.processed_prices.name
}

output "analytics_table" {
  value = aws_glue_catalog_table.analytics_prices.name
}

output "analytics_bucket" {
  value = aws_s3_bucket.analytics.bucket
}

output "athena_workgroup" {
  value = aws_athena_workgroup.crypto.name
}

output "athena_results_prefix" {
  value = "s3://${var.analytics_bucket_name}/query-results/"
}

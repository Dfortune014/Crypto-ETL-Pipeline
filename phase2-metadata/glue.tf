# ---------------------------
# Glue Data Catalog
# ---------------------------

resource "aws_glue_catalog_database" "crypto" {
  name = "crypto_data"
}

# -------- processed_prices (NDJSON.gz in archive bucket) --------
resource "aws_glue_catalog_table" "processed_prices" {
  database_name = aws_glue_catalog_database.crypto.name
  name          = "processed_prices"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification                   = "json"
    "projection.enabled"             = "true"

    "projection.year.type"           = "integer"
    "projection.year.range"          = "2024,2035"
    "projection.year.digits"         = "4"

    "projection.month.type"          = "integer"
    "projection.month.range"         = "1,12"
    "projection.month.digits"        = "2"

    "projection.day.type"            = "integer"
    "projection.day.range"           = "1,31"
    "projection.day.digits"          = "2"

    "projection.hour.type"           = "integer"
    "projection.hour.range"          = "0,23"
    "projection.hour.digits"         = "2"

    # literal ${...} via $${...}
    "storage.location.template"      = "s3://${var.archive_bucket_name}/processed/year=$${year}/month=$${month}/day=$${day}/hour=$${hour}/"
  }

  storage_descriptor {
    location      = "s3://${var.archive_bucket_name}/processed/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "id"
      type = "string"
    }
    columns {
      name = "symbol"
      type = "string"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "current_price"
      type = "double"
    }
    columns {
      name = "market_cap"
      type = "bigint"
    }
    columns {
      name = "market_cap_rank"
      type = "int"
    }
    columns {
      name = "volume_24h"
      type = "bigint"
    }
    columns {
      name = "price_change_pct_1h"
      type = "double"
    }
    columns {
      name = "price_change_pct_24h"
      type = "double"
    }
    columns {
      name = "price_change_pct_7d"
      type = "double"
    }
    columns {
      name = "timestamp"
      type = "bigint"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
  partition_keys {
    name = "hour"
    type = "int"
  }
}

# -------- analytics_prices (Parquet in analytics bucket) --------
resource "aws_glue_catalog_table" "analytics_prices" {
  database_name = aws_glue_catalog_database.crypto.name
  name          = "analytics_prices"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification                   = "parquet"
    "projection.enabled"             = "true"

    "projection.year.type"           = "integer"
    "projection.year.range"          = "2024,2035"
    "projection.year.digits"         = "4"

    "projection.month.type"          = "integer"
    "projection.month.range"         = "1,12"
    "projection.month.digits"        = "2"

    "projection.day.type"            = "integer"
    "projection.day.range"           = "1,31"
    "projection.day.digits"          = "2"

    "projection.hour.type"           = "integer"
    "projection.hour.range"          = "0,23"
    "projection.hour.digits"         = "2"

    # literal ${...} via $${...}
    "storage.location.template"      = "s3://${var.analytics_bucket_name}/analytics/year=$${year}/month=$${month}/day=$${day}/hour=$${hour}/"
  }

  storage_descriptor {
    location      = "s3://${var.analytics_bucket_name}/analytics/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "id"
      type = "string"
    }
    columns {
      name = "symbol"
      type = "string"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "current_price"
      type = "double"
    }
    columns {
      name = "market_cap"
      type = "bigint"
    }
    columns {
      name = "market_cap_rank"
      type = "int"
    }
    columns {
      name = "volume_24h"
      type = "bigint"
    }
    columns {
      name = "price_change_pct_1h"
      type = "double"
    }
    columns {
      name = "price_change_pct_24h"
      type = "double"
    }
    columns {
      name = "price_change_pct_7d"
      type = "double"
    }
    columns {
      name = "timestamp"
      type = "bigint"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }
  partition_keys {
    name = "hour"
    type = "int"
  }
}

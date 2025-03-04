kinesis_stream_name      = "data-stream"
kinesis_shard_count      = 1
kinesis_retention_period = 24

lambda_function_name = "data_processor"
lambda_package       = "lambda_function_payload.zip"
lambda_handler       = "index.handler"
lambda_runtime       = "python3.11"
lambda_exec_role     = "lambda-exec-role"

lambda_code_bucket    = "my-lambda-code-bucket-2688"
data_lake_bucket_name = "my-company-data-lake"
glue_catalog_name     = "data_catalog"

athena_workgroup  = "workgroup"
glue_crawler_role = "crawler-role"
athena_role = "service-role"

tags = {
  environment = "dev"
  project     = "data-processing"
  team        = "analytics" # Si es necesario
}

# region = "us-east-1"  # Cambia esto según la región que necesites
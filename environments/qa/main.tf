module "data_processing" {
  source = "../../modules/data_processing"

  kinesis_stream_name      = local.kinesis_stream_name
  kinesis_shard_count      = var.kinesis_shard_count
  kinesis_retention_period = var.kinesis_retention_period

  lambda_function_name = local.lambda_function_name
  lambda_runtime       = var.lambda_runtime
  lambda_handler       = var.lambda_handler
  lambda_code_bucket   = local.lambda_code_bucket
  lambda_package       = var.lambda_package

  data_lake_bucket_name = local.data_lake_bucket
  glue_catalog_name     = local.glue_catalog_name
  glue_crawler_role     = local.glue_crawler_role   # Role para ejecutar el crawler
  athena_workgroup      = local.athena_workgroup
  lambda_exec_role      = local.lambda_exec_role    # Role para ejecutar la lambda
  athena_role           = var.athena_role        # Role para ejecutar Athena

  tags        = local.common_tags
  suffix      = local.suffix_name
  environment = local.environment

}

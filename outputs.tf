output "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis"
  value       = aws_kinesis_stream.data_stream.name
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.data_processor.function_name
}

output "s3_lambda_code_bucket" {
  description = "Nombre del bucket S3 donde se almacena el código de Lambda"
  value       = aws_s3_bucket.lambda_code_bucket.bucket
}

output "s3_data_lake_bucket" {
  description = "Bucket de S3 para el Data Lake"
  value       = aws_s3_bucket.data_lake.bucket
}

output "glue_catalog_name" {
  description = "Nombre del catálogo de Glue"
  value       = aws_glue_catalog_database.data_catalog.name
}

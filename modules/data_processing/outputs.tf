output "lambda_function_arn" {
  description = "ARN de la función Lambda de procesamiento de datos"
  value       = aws_lambda_function.data_processor.arn
}

output "kinesis_stream_arn" {
  description = "ARN del stream de Kinesis"
  value       = aws_kinesis_stream.data_stream.arn
}

output "glue_database_name" {
  description = "Nombre de la base de datos en Glue"
  value       = aws_glue_catalog_database.data_catalog.name
}

output "glue_crawler_name" {
  description = "Nombre del Glue Crawler"
  value       = aws_glue_crawler.data_crawler.name
}

output "athena_workgroup_name" {
  description = "Nombre del grupo de trabajo de Athena"
  value       = aws_athena_workgroup.athena_workgroup.name
}

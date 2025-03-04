output "lambda_function_arn" {
  description = "ARN de la función Lambda de procesamiento de datos"
  value       = module.data_processing.lambda_function_arn
}

output "kinesis_stream_arn" {
  description = "ARN del stream de Kinesis"
  value       = module.data_processing.kinesis_stream_arn
}

output "glue_database_name" {
  description = "Nombre de la base de datos en Glue"
  value       = module.data_processing.glue_database_name
}

output "glue_crawler_name" {
  description = "Nombre del Glue Crawler"
  value       = module.data_processing.glue_crawler_name
}

output "athena_workgroup_name" {
  description = "Nombre del grupo de trabajo de Athena"
  value       = module.data_processing.athena_workgroup_name
}

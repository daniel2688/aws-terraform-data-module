variable "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis"
  type        = string
}

variable "kinesis_shard_count" {
  description = "Número de shards en el stream de Kinesis"
  type        = number
}

variable "kinesis_retention_period" {
  description = "Período de retención en Kinesis (horas)"
  type        = number
}

variable "lambda_function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime de Lambda"
  type        = string
}

variable "lambda_handler" {
  description = "Handler de Lambda"
  type        = string
}

variable "lambda_code_bucket" {
  description = "Bucket S3 donde se almacena el código de Lambda"
  type        = string
}

variable "lambda_package" {
  description = "Ruta al paquete ZIP de Lambda"
  type        = string
}

variable "data_lake_bucket_name" {
  description = "Nombre del bucket S3 para el Data Lake"
  type        = string
}

variable "glue_catalog_name" {
  description = "Nombre del catálogo de Glue"
  type        = string
}

variable "glue_crawler_role" {
  description = "Nombre del rol de IAM para Glue Crawler"
  type        = string
}

variable "athena_workgroup" {
  description = "Nombre del grupo de trabajo de Athena"
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes para los recursos"
  type        = map(string)
}

variable "suffix" {
  description = "Sufijo para los nombres de los recursos"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, qa, prod)"
  type        = string
}

variable "lambda_exec_role" {
  description = "Nombre del rol de IAM para ejecutar la función Lambda"
  type        = string
  
}

variable "athena_role" {
  description = "Nombre del rol de IAM para ejecutar consultas en Athena"
  type        = string
  
}
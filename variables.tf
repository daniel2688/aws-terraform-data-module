variable "kinesis_stream_name" {
  description = "Nombre del stream de Kinesis"
  type        = string
}

variable "kinesis_shard_count" {
  description = "Número de shards en Kinesis"
  type        = number
}

variable "kinesis_retention_period" {
  description = "Período de retención del stream de Kinesis en horas"
  type        = number
}

variable "lambda_function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "lambda_package" {
  description = "Ruta del archivo ZIP de la función Lambda"
  type        = string
}

variable "lambda_handler" {
  description = "Handler de la función Lambda"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime de la función Lambda"
  type        = string
}

variable "lambda_code_bucket" {
  description = "Nombre del bucket S3 para almacenar el código de Lambda"
  type        = string
}

variable "data_lake_bucket_name" {
  description = "Nombre del bucket de S3 para el Data Lake"
  type        = string
}

variable "glue_catalog_name" {
  description = "Nombre del catálogo de Glue para almacenamiento estructurado"
  type        = string
}

variable "tags" {
  description = "Etiquetas globales para los recursos en AWS"
  type        = map(string)
}

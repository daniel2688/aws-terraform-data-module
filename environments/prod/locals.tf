locals {
  # Acceso directo a los valores desde las etiquetas, asegurando minúsculas
  environment = lower(lookup(var.tags, "environment", "prod"))
  project     = lower(lookup(var.tags, "project", "auna"))
  owner       = lower(replace(lookup(var.tags, "owner", "cloudops"), " ", "-"))

  # Sufijo dinámico sin caracteres no permitidos
  suffix_name = "${local.environment}-${local.project}-${local.owner}"

  # Definir tags comunes incluyendo el sufijo
  common_tags = {
    Project     = local.project
    Environment = local.environment
    Owner       = local.owner
    Suffix      = local.suffix_name
  }

  # Corregir los nombres de los buckets y otros recursos
  kinesis_stream_name  = "kinesis-${local.suffix_name}"
  lambda_function_name = "lambda-${local.suffix_name}"  # Solo minúsculas y guiones
  data_lake_bucket     = "s3-datalake-${replace(local.suffix_name, "_", "-")}" # Guiones, sin _
  lambda_code_bucket   = "s3-lambda-code-${replace(local.suffix_name, "_", "-")}" # Guiones, sin _
  glue_catalog_name    = "glue-catalog-${replace(local.suffix_name, "_", "-")}" # Minúsculas, sin _
  lambda_exec_role     = "lambda-exec-role-${replace(local.suffix_name, "_", "-")}" # Minúsculas, sin _
  glue_crawler_role    = "glue-crawler-role-${replace(local.suffix_name, "_", "-")}" # Minúsculas, sin _
  athena_workgroup     = "athena-${replace(local.suffix_name, "_", "-")}"            # Minúsculas, sin _
  athena_role          = "athena-role-${replace(local.suffix_name, "_", "-")}"       # Minúsculas, sin _  
}

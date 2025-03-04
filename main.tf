# --- Stream de Kinesis ---
resource "aws_kinesis_stream" "data_stream" {
  name             = local.kinesis_stream_name
  shard_count      = 1
  retention_period = 24
  
  tags = var.tags
}

# --- Bucket para almacenar el código de Lambda ---
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = local.lambda_code_bucket
  tags   = var.tags
}

# --- Subir un ZIP vacío a S3 ---
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_code_bucket.bucket
  key    = "lambda/${local.lambda_function_name}.zip"
  source = "lambda_function_payload.zip"
  etag   = filemd5("lambda_function_payload.zip")
}

# --- Lambda Function (Única definición corregida) ---
resource "aws_lambda_function" "data_processor" {
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime

  s3_bucket = aws_s3_bucket.lambda_code_bucket.id
  s3_key    = aws_s3_object.lambda_zip.key

  environment {
    variables = {
      STREAM_NAME      = aws_kinesis_stream.data_stream.name
      DATA_LAKE_BUCKET = aws_s3_bucket.data_lake.bucket
    }
  }

  tags = var.tags
}

# --- IAM Role para Lambda ---
resource "aws_iam_role" "lambda_exec" {
  name = local.lambda_exec_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# --- Vincular Lambda con Kinesis ---
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.data_stream.arn
  function_name     = aws_lambda_function.data_processor.arn
  starting_position = "LATEST"
  batch_size        = 100
}

# --- Permisos para Lambda en S3 ---
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_policy"
  description = "Permitir que Lambda escriba en el Data Lake (S3)"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.data_lake.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# --- Data Lake (S3) ---
resource "aws_s3_bucket" "data_lake" {
  bucket = local.data_lake_bucket
  tags   = var.tags
}

# --- Configuración de encriptación para S3 Data Lake ---
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Política de seguridad en S3 ---
resource "aws_s3_bucket_policy" "data_lake_policy" {
  bucket = aws_s3_bucket.data_lake.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.data_lake.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

# --- AWS Glue Catalog ---
resource "aws_glue_catalog_database" "data_catalog" {
  name = local.glue_catalog_name
  tags = var.tags
}

# --- Crear un Crawler de Glue para el Data Lake ---
resource "aws_glue_crawler" "data_crawler" {
  name          = "crawler-${local.suffix_name}"
  database_name = aws_glue_catalog_database.data_catalog.name
  role          = aws_iam_role.glue_role.arn  #  Ahora está correctamente definido

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/"
  }

  schedule = "cron(0 12 * * ? *)" # Corre cada día a las 12 PM UTC

  tags = var.tags
}

# --- IAM Role para Glue Crawler ---
resource "aws_iam_role" "glue_role" {
  name = "glue-role-${local.suffix_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# --- Permisos de Glue para acceder a S3 y Glue Catalog ---
resource "aws_iam_policy" "glue_s3_policy" {
  name        = "glue_s3_policy-${local.suffix_name}"
  description = "Permitir que Glue acceda a S3 y Glue Catalog"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:CreateTable",
          "glue:UpdateTable"
        ],
        Resource = "*"
      }
    ]
  })
}

# --- Asociar la política al rol de Glue ---
resource "aws_iam_role_policy_attachment" "glue_s3_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_policy.arn
}

# --- Política IAM para permitir a Lambda acceder a Kinesis ---
resource "aws_iam_policy" "lambda_kinesis_policy" {
  name        = "lambda_kinesis_policy"
  description = "Permitir que Lambda lea de Kinesis Stream"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:ListStreams",
          "kinesis:PutRecord"
        ],
        Resource = aws_kinesis_stream.data_stream.arn
      }
    ]
  })
}

# --- Asociar la política de Kinesis al rol de Lambda ---
resource "aws_iam_role_policy_attachment" "lambda_kinesis_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_kinesis_policy.arn
}

# --- Política IAM para permitir a Lambda escribir logs en CloudWatch ---
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  description = "Permitir que Lambda escriba logs en CloudWatch Logs"
  
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# --- Asociar la política de CloudWatch a la IAM Role de Lambda ---
resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

# --- Grupo de Logs en CloudWatch para Lambda ---
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 7  # Mantiene los logs por 7 días
}

# --- Política de S3 para el bucket de Athena ---
resource "aws_s3_bucket_policy" "athena_results_policy" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = { "Service": "athena.amazonaws.com" },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.athena_results_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption": "AES256"
          }
        }
      },
      {
        Effect   = "Allow",
        Principal = { "Service": "athena.amazonaws.com" },
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          aws_s3_bucket.athena_results_bucket.arn,
          "${aws_s3_bucket.athena_results_bucket.arn}/*"
        ]
      }
    ]
  })
}

# --- IAM Role para Athena ---
resource "aws_iam_role" "athena_role" {
  name = "athena-exec-role-${local.suffix_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "athena.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# --- Permisos para Athena sobre el bucket de resultados ---
resource "aws_iam_policy" "athena_s3_policy" {
  name        = "athena_s3_policy-${local.suffix_name}"
  description = "Permitir que Athena escriba en el bucket de resultados"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.athena_results_bucket.arn}", # El bucket
          "${aws_s3_bucket.athena_results_bucket.arn}/*" # Todos los objetos
        ]
      }
    ]
  })
}

# --- Configuración de encriptación para S3 Athena ---
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_s3_encryption" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Asociar la política de S3 al rol de Athena ---
resource "aws_iam_role_policy_attachment" "athena_s3_attach" {
  role       = aws_iam_role.athena_role.name
  policy_arn = aws_iam_policy.athena_s3_policy.arn
}

# --- Bucket para almacenar resultados de Athena ---
resource "aws_s3_bucket" "athena_results_bucket" {
  bucket = "s3-athena-results-${local.suffix_name}"
  tags   = var.tags
}

# --- Workgroup de Athena configurado con el bucket de resultados ---
resource "aws_athena_workgroup" "athena_workgroup" {
  name = "athena-dev-data-processing"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/"
      encryption_configuration {
        encryption_option = "SSE_S3" # Asegura que los resultados se almacenen cifrados con S3
      }
    }
  }

  force_destroy = true # Permite eliminar el workgroup con terraform destroy
  tags = var.tags
}

# --- Grupo de Logs en CloudWatch para Glue Crawler ---
resource "aws_cloudwatch_log_group" "glue_crawler_logs" {
  name              = "/aws-glue/crawlers"
  retention_in_days = 7
}

# --- IAM Policy para permitir a Glue escribir logs en CloudWatch --
resource "aws_iam_policy" "glue_logging_policy" {
  name        = "glue_logging_policy-${local.suffix_name}"
  description = "Permitir que Glue escriba logs en CloudWatch Logs"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# --- Asociar la política de CloudWatch a la IAM Role de Glue ---
resource "aws_iam_role_policy_attachment" "glue_logging_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_logging_policy.arn
}

# --- Permisos de Glue para acceder a S3 y Glue Catalog ---
resource "aws_s3_bucket_policy" "glue_data_lake_policy" {
  bucket = aws_s3_bucket.data_lake.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = { "Service": "glue.amazonaws.com" },
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.data_lake.arn}",
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}

# --- Política IAM para permitir acceso total a Glue ---
resource "aws_iam_policy" "glue_full_access" {
  name        = "glue_full_access"
  description = "Permitir acceso completo a AWS Glue en pruebas"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "glue:*",  # Permite acceso total a Glue
        Resource = "*"
      }
    ]
  })
}

# --- Asociar la política al rol de Glue ---
resource "aws_iam_role_policy_attachment" "glue_catalog_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_full_access.arn
}

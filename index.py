import json
import boto3
import base64
import os
import logging

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

def lambda_handler(event, context):
    logger.info("🚀 Evento recibido: %s", json.dumps(event, indent=2))

    # Verificar si el evento contiene la clave "Records"
    if "Records" not in event:
        logger.error("❌ El evento recibido no contiene la clave 'Records'.")
        return {"statusCode": 400, "body": "Formato de evento incorrecto."}

    records = []
    for record in event["Records"]:
        try:
            # Decodificar los datos de Kinesis
            payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
            records.append(json.loads(payload))
        except Exception as e:
            logger.error("❌ Error al procesar el registro de Kinesis: %s", str(e))

    # Si no hay registros procesados, evitar escribir en S3
    if not records:
        logger.warning("⚠️ No se encontraron registros válidos para guardar en S3.")
        return {"statusCode": 204, "body": "No hay datos para procesar."}

    # Obtener el bucket de la variable de entorno
    bucket_name = os.environ.get("DATA_LAKE_BUCKET", "s3-datalake-dev-data-processing-auna")
    file_key = f"processed_data/{context.aws_request_id}.json"

    try:
        # Guardar los datos en S3 con encriptación AES256
        s3.put_object(
            Bucket=bucket_name,
            Key=file_key,
            Body=json.dumps(records),
            ContentType="application/json",
            ServerSideEncryption="AES256"  # ✅ Agregar encriptación AES256
        )
        logger.info(f"✅ Datos guardados en S3: {file_key}")
    except Exception as e:
        logger.error("❌ Error al escribir en S3: %s", str(e))
        return {"statusCode": 500, "body": "Error al guardar los datos en S3."}

    return {"statusCode": 200, "body": "Procesado correctamente"}

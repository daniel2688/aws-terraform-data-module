import boto3
import json
import base64

# Inicializar el cliente de Kinesis
kinesis = boto3.client("kinesis")

# Datos a enviar
data = {"sensor_id": "1234", "temperature": 27.5, "status": "OK"}

try:
    # Enviar el registro a Kinesis
    response = kinesis.put_record(
        StreamName="kinesis-dev-data-processing-auna",  # Asegúrate de que el stream existe
        Data=json.dumps(data),  # Convertir el diccionario a JSON
        PartitionKey="test"  # Clave de partición para distribuir la carga
    )

    print("✅ Registro enviado con éxito:", response)

except Exception as e:
    print("❌ Error al enviar el registro a Kinesis:", str(e))

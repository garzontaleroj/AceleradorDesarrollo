# Plantilla: Consumidor Kafka — Streaming Integrator

## Descripción
Aplicación Siddhi que consume eventos desde un topic de Kafka, los procesa
y los envía a un destino (log, HTTP, o base de datos).

## Caso de uso
Procesar eventos en tiempo real desde un broker Kafka — ideal para 
Event-Driven Architecture con WSO2 Streaming Integrator.

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `KafkaConsumer.siddhi` | Siddhi App | Aplicación de procesamiento de eventos |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `APP_NAME` | Nombre de la aplicación Siddhi | `PedidosConsumer` |
| `KAFKA_BOOTSTRAP` | Servidores Kafka | `kafka:9092` |
| `KAFKA_TOPIC` | Topic a consumir | `pedidos.creados` |
| `CONSUMER_GROUP` | Consumer group ID | `si-pedidos-group` |
| `EVENT_SCHEMA` | Campos del evento | ver plantilla |

## Prerequisitos
- Conector Kafka instalado en SI (`{SI_HOME}/lib/`)
- Kafka accesible desde el SI
- Topic creado previamente

## Despliegue
```bash
# Copiar al directorio de Siddhi Apps
cp KafkaConsumer.siddhi {SI_HOME}/deployment/siddhi-files/

# O vía API REST del SI
curl -X POST https://si-host:9443/siddhi-apps \
  -H "Content-Type: text/plain" \
  -u admin:admin \
  -d @KafkaConsumer.siddhi
```

# Plantilla: Store and Forward — Micro Integrator

## Descripción
Patrón de mensajería garantizada (Guaranteed Delivery) usando Message Store
y Message Processor. Los mensajes se persisten en un store y un processor
los reenvía al backend de forma asíncrona, reintentando si falla.

## Caso de uso
- Integración con backends que pueden estar temporalmente no disponibles
- Colas de procesamiento desacopladas
- Escenarios de fire-and-forget con garantía de entrega

## Artefactos
| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `StoreForwardAPI.xml` | API | Recibe mensajes y los almacena |
| `MessageStoreConfig.xml` | MessageStore | Configuración del store |
| `ForwardingProcessor.xml` | MessageProcessor | Processor que reenvía |
| `variables.yaml` | Config | Variables de la plantilla |

## Variables
| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `API_NAME` | Nombre de la API receptora | `OrderIngestionAPI` |
| `API_CONTEXT` | Contexto URL | `/orders/ingest` |
| `STORE_NAME` | Nombre del Message Store | `OrderMessageStore` |
| `PROCESSOR_NAME` | Nombre del Message Processor | `OrderForwardProcessor` |
| `BACKEND_URL` | URL destino final | `http://order-service:8080/api/orders` |
| `RETRY_INTERVAL` | Intervalo de reintento (ms) | `5000` |
| `MAX_DELIVERY_ATTEMPTS` | Intentos máximos | `5` |

## Flujo
```
1. Cliente → MI API: POST /orders/ingest (mensaje)
2. MI → Message Store: Almacenar mensaje (respuesta inmediata 202)
3. Message Processor: Poll del store cada N ms
4. Processor → Backend: Reenviar mensaje
5. Si falla → reintentar con backoff (hasta MAX_DELIVERY_ATTEMPTS)
6. Si éxito → remover del store
```

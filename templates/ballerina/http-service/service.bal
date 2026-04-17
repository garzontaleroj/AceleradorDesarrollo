// =============================================================================
// Plantilla: Servicio HTTP REST con CRUD
// Lenguaje:  Ballerina
//
// Variables:
//   {{SERVICE_PORT}}   - Puerto del servicio (ej: 9090)
//   {{BASE_PATH}}      - Ruta base (ej: /api/v1)
//   {{RESOURCE_NAME}}  - Nombre del recurso (ej: Product)
// =============================================================================

import ballerina/http;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;

// Almacenamiento en memoria (reemplazar con DB en producción)
isolated map<{{RESOURCE_NAME}}> resourceStore = {};

service "{{BASE_PATH}}" on new http:Listener({{SERVICE_PORT}}) {

    // GET /recursos - Listar todos
    isolated resource function get resources(int offset = 0, int 'limit = 20)
            returns {{RESOURCE_NAME}}List|http:InternalServerError {
        do {
            lock {
                {{RESOURCE_NAME}}[] items = resourceStore.toArray();
                int total = items.length();
                int end = offset + 'limit;
                if end > total {
                    end = total;
                }
                {{RESOURCE_NAME}}[] page = offset < total ? items.slice(offset, end) : [];
                return {
                    data: page.clone(),
                    total: total,
                    offset: offset,
                    'limit: 'limit
                };
            }
        } on fail error e {
            log:printError("Error listando recursos", 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // GET /recursos/{id} - Obtener por ID
    isolated resource function get resources/[string id]()
            returns {{RESOURCE_NAME}}|http:NotFound|http:InternalServerError {
        do {
            lock {
                if resourceStore.hasKey(id) {
                    return resourceStore.get(id).clone();
                }
                return http:NOT_FOUND;
            }
        } on fail error e {
            log:printError("Error obteniendo recurso", 'error = e, id = id);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // POST /recursos - Crear
    isolated resource function post resources(@http:Payload {{RESOURCE_NAME}}Input input)
            returns {{RESOURCE_NAME}}|http:BadRequest|http:InternalServerError {
        do {
            if input.name.trim().length() == 0 {
                return http:BAD_REQUEST;
            }
            string id = uuid:createType1AsString();
            string now = time:utcToString(time:utcNow());
            {{RESOURCE_NAME}} item = {
                id: id,
                name: input.name,
                description: input.description ?: "",
                createdAt: now,
                updatedAt: now
            };
            lock {
                resourceStore[id] = item.clone();
            }
            log:printInfo("Recurso creado", id = id, name = input.name);
            return item;
        } on fail error e {
            log:printError("Error creando recurso", 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // PUT /recursos/{id} - Actualizar
    isolated resource function put resources/[string id](@http:Payload {{RESOURCE_NAME}}Input input)
            returns {{RESOURCE_NAME}}|http:NotFound|http:BadRequest|http:InternalServerError {
        do {
            if input.name.trim().length() == 0 {
                return http:BAD_REQUEST;
            }
            lock {
                if !resourceStore.hasKey(id) {
                    return http:NOT_FOUND;
                }
                {{RESOURCE_NAME}} existing = resourceStore.get(id);
                string now = time:utcToString(time:utcNow());
                {{RESOURCE_NAME}} updated = {
                    id: id,
                    name: input.name,
                    description: input.description ?: existing.description,
                    createdAt: existing.createdAt,
                    updatedAt: now
                };
                resourceStore[id] = updated.clone();
                log:printInfo("Recurso actualizado", id = id);
                return updated.clone();
            }
        } on fail error e {
            log:printError("Error actualizando recurso", 'error = e, id = id);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // DELETE /recursos/{id} - Eliminar
    isolated resource function delete resources/[string id]()
            returns http:NoContent|http:NotFound|http:InternalServerError {
        do {
            lock {
                if !resourceStore.hasKey(id) {
                    return http:NOT_FOUND;
                }
                _ = resourceStore.remove(id);
            }
            log:printInfo("Recurso eliminado", id = id);
            return http:NO_CONTENT;
        } on fail error e {
            log:printError("Error eliminando recurso", 'error = e, id = id);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // GET /health - Health check
    isolated resource function get health() returns json {
        return {status: "UP", service: "{{PACKAGE_NAME}}"};
    }
}

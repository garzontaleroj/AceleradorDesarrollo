import ballerina/http;
import ballerina/log;

// =============================================================================
// Servicio de ejemplo — Health check y mediación básica
// =============================================================================

configurable int port = 8090;
configurable string backendUrl = "http://localhost:8080";

final http:Client backendClient = check new (backendUrl);

service /api on new http:Listener(port) {

    // Health check
    resource function get health() returns json {
        return {
            status: "UP",
            service: "ballerina-integration",
            timestamp: time:utcNow().toString()
        };
    }

    // Proxy a backend con transformación
    resource function get data(http:Request req) returns json|error {
        log:printInfo("Proxying request to backend");

        json response = check backendClient->get("/api/v1/data");

        // Transformar respuesta
        json transformed = check transform(response);
        return transformed;
    }

    // POST con validación
    resource function post data(http:Request req) returns json|error {
        json payload = check req.getJsonPayload();
        log:printInfo("Received POST request", payload = payload.toString());

        // Validar payload
        if !check validatePayload(payload) {
            return error("Invalid payload");
        }

        json response = check backendClient->post("/api/v1/data", payload);
        return response;
    }
}

// Función de transformación
function transform(json input) returns json|error {
    return {
        data: check input.data,
        processedBy: "ballerina-integration",
        processedAt: time:utcNow().toString()
    };
}

// Función de validación
function validatePayload(json payload) returns boolean|error {
    map<json> payloadMap = check payload.ensureType();
    return payloadMap.hasKey("id") && payloadMap.hasKey("name");
}

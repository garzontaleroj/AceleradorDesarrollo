// =============================================================================
// Tests unitarios para servicio HTTP
// =============================================================================

import ballerina/http;
import ballerina/test;

http:Client testClient = check new ("http://localhost:{{SERVICE_PORT}}/{{BASE_PATH}}");

@test:Config {}
function testHealthEndpoint() returns error? {
    json response = check testClient->get("/health");
    test:assertEquals(response.status, "UP");
}

@test:Config {}
function testCreateResource() returns error? {
    {{RESOURCE_NAME}}Input input = {name: "Test Item", description: "Descripción de prueba"};
    {{RESOURCE_NAME}} response = check testClient->post("/resources", input);
    test:assertEquals(response.name, "Test Item");
    test:assertNotEquals(response.id, "");
}

@test:Config {dependsOn: [testCreateResource]}
function testListResources() returns error? {
    {{RESOURCE_NAME}}List response = check testClient->get("/resources");
    test:assertTrue(response.total > 0);
    test:assertTrue(response.data.length() > 0);
}

@test:Config {}
function testGetNonExistentResource() {
    {{RESOURCE_NAME}}|error response = testClient->get("/resources/non-existent-id");
    if response is http:ClientRequestError {
        test:assertEquals(response.detail().statusCode, 404);
    } else {
        test:assertFail("Se esperaba un error 404");
    }
}

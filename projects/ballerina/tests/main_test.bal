import ballerina/http;
import ballerina/test;

@test:Config {}
function testHealthEndpoint() returns error? {
    http:Client testClient = check new ("http://localhost:8090");
    json response = check testClient->get("/api/health");
    test:assertEquals(check response.status, "UP");
}

@test:Config {}
function testValidatePayload() {
    json validPayload = {id: "123", name: "test"};
    boolean|error result = validatePayload(validPayload);
    if result is boolean {
        test:assertTrue(result);
    } else {
        test:assertFail("Should not return error for valid payload");
    }
}

@test:Config {}
function testValidatePayloadInvalid() {
    json invalidPayload = {foo: "bar"};
    boolean|error result = validatePayload(invalidPayload);
    if result is boolean {
        test:assertFalse(result);
    }
}

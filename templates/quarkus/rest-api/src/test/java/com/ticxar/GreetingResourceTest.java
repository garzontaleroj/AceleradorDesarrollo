package com.ticxar;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
class GreetingResourceTest {

    @Test
    void testHelloEndpoint() {
        given()
                .when().get("/hello")
                .then()
                .statusCode(200)
                .body(is("Hello from Quarkus REST — TICXAR Acelerador"));
    }

    @Test
    void testListItems() {
        given()
                .when().get("/items")
                .then()
                .statusCode(200)
                .body("size()", is(2));
    }

    @Test
    void testCreateItem() {
        given()
                .contentType("application/json")
                .body("{\"name\": \"Nuevo Item\", \"description\": \"Test\"}")
                .when().post("/items")
                .then()
                .statusCode(201)
                .body("id", notNullValue())
                .body("name", is("Nuevo Item"));
    }

    @Test
    void testGetItemNotFound() {
        given()
                .when().get("/items/9999")
                .then()
                .statusCode(404);
    }
}

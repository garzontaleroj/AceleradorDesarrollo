package com.ticxar;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

@Path("/hello")
@Tag(name = "Greeting", description = "Endpoint de saludo")
public class GreetingResource {

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @Operation(summary = "Saludo", description = "Retorna un saludo de ejemplo")
    public String hello() {
        return "Hello from Quarkus REST — TICXAR Acelerador";
    }
}

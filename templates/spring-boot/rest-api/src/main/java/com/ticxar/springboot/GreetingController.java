package com.ticxar.springboot;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Greeting", description = "Endpoint de saludo")
public class GreetingController {

    @GetMapping("/hello")
    @Operation(summary = "Saludo", description = "Retorna un saludo de ejemplo")
    public String hello() {
        return "Hello from Spring Boot — TICXAR Acelerador";
    }
}

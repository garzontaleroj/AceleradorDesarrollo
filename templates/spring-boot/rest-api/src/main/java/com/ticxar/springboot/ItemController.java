package com.ticxar.springboot;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/items")
@Tag(name = "Items", description = "Operaciones CRUD sobre Items")
public class ItemController {

    private final ItemService service;

    public ItemController(ItemService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Listar todos los items")
    public List<Item> list() {
        return service.listAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtener un item por ID")
    @ApiResponse(responseCode = "200", description = "Item encontrado")
    @ApiResponse(responseCode = "404", description = "Item no encontrado")
    public ResponseEntity<Item> getById(
            @Parameter(description = "ID del item") @PathVariable Long id) {
        return service.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @Operation(summary = "Crear un nuevo item")
    @ApiResponse(responseCode = "201", description = "Item creado")
    public ResponseEntity<Item> create(@Valid @RequestBody Item item) {
        Item created = service.create(item);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar un item existente")
    @ApiResponse(responseCode = "200", description = "Item actualizado")
    @ApiResponse(responseCode = "404", description = "Item no encontrado")
    public ResponseEntity<Item> update(
            @Parameter(description = "ID del item") @PathVariable Long id,
            @Valid @RequestBody Item item) {
        return service.update(id, item)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Eliminar un item")
    @ApiResponse(responseCode = "204", description = "Item eliminado")
    @ApiResponse(responseCode = "404", description = "Item no encontrado")
    public ResponseEntity<Void> delete(
            @Parameter(description = "ID del item") @PathVariable Long id) {
        if (service.delete(id)) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}

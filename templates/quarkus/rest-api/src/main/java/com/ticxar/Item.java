package com.ticxar;

import org.eclipse.microprofile.openapi.annotations.media.Schema;

@Schema(description = "Entidad de ejemplo para operaciones CRUD")
public class Item {

    @Schema(description = "Identificador único", example = "1")
    private Long id;

    @Schema(description = "Nombre del item", example = "Item de prueba", required = true)
    private String name;

    @Schema(description = "Descripción del item", example = "Descripción de ejemplo")
    private String description;

    public Item() {
    }

    public Item(Long id, String name, String description) {
        this.id = id;
        this.name = name;
        this.description = description;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}

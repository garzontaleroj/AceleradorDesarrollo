package com.ticxar;

import java.util.List;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.parameters.Parameter;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

@Path("/items")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Items", description = "Operaciones CRUD sobre Items")
public class ItemResource {

    @Inject
    ItemService service;

    @GET
    @Operation(summary = "Listar todos los items")
    public List<Item> list() {
        return service.listAll();
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Obtener un item por ID")
    @APIResponse(responseCode = "200", description = "Item encontrado")
    @APIResponse(responseCode = "404", description = "Item no encontrado")
    public Response getById(
            @Parameter(description = "ID del item") @PathParam("id") Long id) {
        return service.findById(id)
                .map(item -> Response.ok(item).build())
                .orElse(Response.status(Response.Status.NOT_FOUND).build());
    }

    @POST
    @Operation(summary = "Crear un nuevo item")
    @APIResponse(responseCode = "201", description = "Item creado")
    public Response create(Item item) {
        Item created = service.create(item);
        return Response.status(Response.Status.CREATED).entity(created).build();
    }

    @PUT
    @Path("/{id}")
    @Operation(summary = "Actualizar un item existente")
    @APIResponse(responseCode = "200", description = "Item actualizado")
    @APIResponse(responseCode = "404", description = "Item no encontrado")
    public Response update(
            @Parameter(description = "ID del item") @PathParam("id") Long id,
            Item item) {
        return service.update(id, item)
                .map(updated -> Response.ok(updated).build())
                .orElse(Response.status(Response.Status.NOT_FOUND).build());
    }

    @DELETE
    @Path("/{id}")
    @Operation(summary = "Eliminar un item")
    @APIResponse(responseCode = "204", description = "Item eliminado")
    @APIResponse(responseCode = "404", description = "Item no encontrado")
    public Response delete(
            @Parameter(description = "ID del item") @PathParam("id") Long id) {
        if (service.delete(id)) {
            return Response.noContent().build();
        }
        return Response.status(Response.Status.NOT_FOUND).build();
    }
}

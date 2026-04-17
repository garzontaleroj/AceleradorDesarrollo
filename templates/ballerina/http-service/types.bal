// =============================================================================
// Plantilla: Tipos de dominio para servicio HTTP
// Lenguaje:  Ballerina
//
// PERSONALIZAR: Modificar los records según el modelo de datos del proyecto
// =============================================================================

// Recurso principal
public type {{RESOURCE_NAME}} record {|
    readonly string id;
    string name;
    string description;
    string createdAt;
    string updatedAt;
|};

// Input para crear/actualizar recurso
public type {{RESOURCE_NAME}}Input record {|
    string name;
    string description?;
|};

// Respuesta de lista paginada
public type {{RESOURCE_NAME}}List record {|
    {{RESOURCE_NAME}}[] data;
    int total;
    int offset;
    int 'limit;
|};

// Respuesta de error estándar
public type ErrorResponse record {|
    string code;
    string message;
    string? details;
|};

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from .models import ItemCreate, ItemResponse, ItemUpdate
from .service import ItemService

app = FastAPI(
    title="TICXAR FastAPI REST API",
    description="API REST de ejemplo para el Acelerador TICXAR",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

service = ItemService()


@app.get("/hello", tags=["Greeting"])
def hello() -> dict:
    """Retorna un saludo de ejemplo."""
    return {"message": "Hello from FastAPI — TICXAR Acelerador"}


@app.get("/health", tags=["Health"])
def health() -> dict:
    """Health check del servicio."""
    return {"status": "UP"}


@app.get("/api/items", response_model=list[ItemResponse], tags=["Items"])
def list_items() -> list[ItemResponse]:
    """Listar todos los items."""
    return service.list_all()


@app.get("/api/items/{item_id}", response_model=ItemResponse, tags=["Items"])
def get_item(item_id: int) -> ItemResponse:
    """Obtener un item por ID."""
    item = service.find_by_id(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    return item


@app.post(
    "/api/items",
    response_model=ItemResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Items"],
)
def create_item(item: ItemCreate) -> ItemResponse:
    """Crear un nuevo item."""
    return service.create(item)


@app.put("/api/items/{item_id}", response_model=ItemResponse, tags=["Items"])
def update_item(item_id: int, item: ItemUpdate) -> ItemResponse:
    """Actualizar un item existente."""
    updated = service.update(item_id, item)
    if updated is None:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    return updated


@app.delete(
    "/api/items/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["Items"],
)
def delete_item(item_id: int) -> None:
    """Eliminar un item."""
    if not service.delete(item_id):
        raise HTTPException(status_code=404, detail="Item no encontrado")

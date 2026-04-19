from threading import Lock
from typing import Optional

from .models import ItemCreate, ItemResponse, ItemUpdate


class ItemService:
    """Servicio de negocio para Items con almacenamiento in-memory."""

    def __init__(self) -> None:
        self._items: dict[int, dict] = {}
        self._counter: int = 0
        self._lock = Lock()
        # Datos iniciales de ejemplo
        self.create(ItemCreate(name="Item 1", description="Primer item de ejemplo"))
        self.create(ItemCreate(name="Item 2", description="Segundo item de ejemplo"))

    def list_all(self) -> list[ItemResponse]:
        return [ItemResponse(**data) for data in self._items.values()]

    def find_by_id(self, item_id: int) -> Optional[ItemResponse]:
        data = self._items.get(item_id)
        if data is None:
            return None
        return ItemResponse(**data)

    def create(self, item: ItemCreate) -> ItemResponse:
        with self._lock:
            self._counter += 1
            new_id = self._counter
        data = {"id": new_id, "name": item.name, "description": item.description}
        self._items[new_id] = data
        return ItemResponse(**data)

    def update(self, item_id: int, item: ItemUpdate) -> Optional[ItemResponse]:
        if item_id not in self._items:
            return None
        data = {"id": item_id, "name": item.name, "description": item.description}
        self._items[item_id] = data
        return ItemResponse(**data)

    def delete(self, item_id: int) -> bool:
        return self._items.pop(item_id, None) is not None

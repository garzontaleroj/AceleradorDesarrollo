from pydantic import BaseModel, Field
from typing import Optional


class ItemCreate(BaseModel):
    """Datos para crear un item."""

    name: str = Field(..., min_length=1, max_length=200, examples=["Item de prueba"])
    description: Optional[str] = Field(
        None, max_length=500, examples=["Descripción de ejemplo"]
    )


class ItemUpdate(BaseModel):
    """Datos para actualizar un item."""

    name: str = Field(..., min_length=1, max_length=200, examples=["Item actualizado"])
    description: Optional[str] = Field(
        None, max_length=500, examples=["Nueva descripción"]
    )


class ItemResponse(BaseModel):
    """Representación de un item en las respuestas."""

    id: int = Field(..., examples=[1])
    name: str = Field(..., examples=["Item de prueba"])
    description: Optional[str] = Field(None, examples=["Descripción de ejemplo"])

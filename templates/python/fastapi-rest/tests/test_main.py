from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_hello():
    response = client.get("/hello")
    assert response.status_code == 200
    assert "Hello" in response.json()["message"]


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "UP"


def test_list_items():
    response = client.get("/api/items")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2


def test_create_item():
    payload = {"name": "Nuevo Item", "description": "Creado en test"}
    response = client.post("/api/items", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Nuevo Item"
    assert "id" in data


def test_get_item():
    response = client.get("/api/items/1")
    assert response.status_code == 200
    assert response.json()["id"] == 1


def test_update_item():
    payload = {"name": "Actualizado", "description": "Desc actualizada"}
    response = client.put("/api/items/1", json=payload)
    assert response.status_code == 200
    assert response.json()["name"] == "Actualizado"


def test_get_item_not_found():
    response = client.get("/api/items/9999")
    assert response.status_code == 404


def test_delete_item_not_found():
    response = client.delete("/api/items/9999")
    assert response.status_code == 404

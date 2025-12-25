import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "IA_Sandbox API", "version": "0.1.0"}

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_get_requirements():
    response = client.get("/api/requirements")
    assert response.status_code == 200
    data = response.json()
    assert "requirements" in data
    assert len(data["requirements"]) == 12
    assert data["requirements"][0]["id"] == "REQ_01"

def test_get_maturity_levels():
    response = client.get("/api/maturity-levels")
    assert response.status_code == 200
    data = response.json()
    assert "levels" in data
    assert len(data["levels"]) == 8
    assert data["levels"][0]["code"] == "L1"

def test_calculate_plan_endpoint():
    response = client.post("/api/calculate-plan", json={"maturity_level": "L3"})
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["maturity_level"] == "L3"
    assert data["adaptation_plan"] == {'code': '02', 'description': 'Implementar'}

def test_calculate_assessments_endpoint():
    payload = [
        {"measure_id": "MG_01", "difficulty": "01", "maturity": "L1"},
        {"measure_id": "MG_02", "difficulty": "02", "maturity": "L8"}
    ]
    response = client.post("/api/calculate-assessments", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert len(data["assessments"]) == 2
    assert data["assessments"][0]["adaptation_plan"] == "01"
    assert data["assessments"][1]["adaptation_plan"] == "05"

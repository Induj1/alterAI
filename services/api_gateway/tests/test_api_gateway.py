from __future__ import annotations

from fastapi.testclient import TestClient

from alter_api_gateway.api import app
from alter_api_gateway.config import Settings
from alter_api_gateway.schemas import MissionBriefingRequest
from alter_api_gateway.service import ApiGatewayService


def test_routes_include_core_services() -> None:
    service = ApiGatewayService(Settings())

    routes = {route.name for route in service.routes()}

    assert "voice_gateway" in routes
    assert "future_simulation" in routes
    assert "officekit" in routes


def test_mission_briefing_returns_cross_device_sequence() -> None:
    service = ApiGatewayService(Settings())

    response = service.mission_briefing(
        MissionBriefingRequest(objective="Choose between startup and research")
    )

    assert "voice_gateway" in response.phone_layer
    assert "clone_council" in response.laptop_layer
    assert response.recommended_sequence
    assert response.route_targets


def test_api_routes_endpoint() -> None:
    client = TestClient(app)

    response = client.get("/v1/gateway/routes")

    assert response.status_code == 200
    assert any(item["name"] == "alter_lens" for item in response.json())


def test_demo_endpoint_returns_story_even_when_services_are_unavailable() -> None:
    client = TestClient(app)

    response = client.post(
        "/v1/demo/future-os",
        json={"objective": "Choose the best hackathon launch path"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["headline"]
    assert payload["steps"]
    assert "systems" in payload["key_metrics"]

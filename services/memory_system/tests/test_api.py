from __future__ import annotations

from fastapi.testclient import TestClient

from alter_memory_system.api import app


def test_memory_api_create_and_search() -> None:
    client = TestClient(app)
    user_id = "11111111-1111-4111-8111-111111111111"

    create_response = client.post(
        "/v1/memory/items",
        json={
            "user_id": user_id,
            "memory_type": "project",
            "title": "ALTER Clone Council",
            "summary": "Built a multi-agent debate system.",
            "content": "The user created a LangGraph Clone Council service.",
            "confidence": 0.9,
            "importance": 0.82,
        },
    )
    assert create_response.status_code == 200

    search_response = client.post(
        "/v1/memory/search",
        json={
            "user_id": user_id,
            "query": "LangGraph agent council",
            "limit": 5,
        },
    )

    assert search_response.status_code == 200
    assert search_response.json()["hits"][0]["memory"]["title"] == "ALTER Clone Council"


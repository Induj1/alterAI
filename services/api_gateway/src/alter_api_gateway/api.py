from __future__ import annotations

from functools import lru_cache

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .schemas import (
    ArchitectureResponse,
    DemoRunRequest,
    DemoRunResponse,
    HealthResponse,
    IntelligenceDecisionRequest,
    IntelligenceDecisionResponse,
    MissionBriefingRequest,
    MissionBriefingResponse,
    OutcomeUpdateRequest,
    OutcomeUpdateResponse,
    ServiceRoute,
    SystemHealthResponse,
    VoiceActionRuntimeRequest,
    VoiceActionRuntimeResponse,
)
from .service import ApiGatewayService, create_api_gateway_service

app = FastAPI(
    title="ALTER API Gateway",
    version="0.1.0",
    description="Client-facing API gateway for ALTER.",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@lru_cache(maxsize=1)
def get_service() -> ApiGatewayService:
    return create_api_gateway_service()


@app.get("/healthz", response_model=HealthResponse)
async def healthz() -> HealthResponse:
    settings = get_settings()
    return HealthResponse(
        status="ok",
        service="alter-api-gateway",
        environment=settings.gateway_env,
    )


@app.get("/v1/gateway/architecture", response_model=ArchitectureResponse)
async def architecture() -> ArchitectureResponse:
    return ArchitectureResponse(
        service="alter-api-gateway",
        components=[
            "service registry",
            "health aggregator",
            "mission briefing composer",
            "intelligence kernel orchestrator",
            "outcome learning loop",
            "voice action runtime",
            "client route discovery",
        ],
        data_flow=[
            "Clients call the gateway as the edge entrypoint.",
            "Gateway exposes route discovery for feature services.",
            "Gateway checks downstream service health.",
            "Mission briefing composes the phone and laptop execution sequence.",
            "Decision Intelligence retrieves memory, simulates futures, debates the council, ranks opportunities, and writes back durable memory.",
            "Outcome Learning turns recommendations into experiments, captures reality, writes outcome memory, and updates reputation.",
            "Voice Action Runtime turns Hey Alter transcripts into intent, reasoning, action graph, spoken response, and follow-up.",
        ],
        output_contract={
            "SystemHealthResponse": ["status", "services", "checked_at"],
            "MissionBriefingResponse": [
                "command_summary",
                "phone_layer",
                "laptop_layer",
                "recommended_sequence",
                "route_targets",
            ],
            "DemoRunResponse": [
                "headline",
                "executive_summary",
                "steps",
                "key_metrics",
                "next_actions",
            ],
            "IntelligenceDecisionResponse": [
                "recommendation",
                "confidence_score",
                "experiment_plan",
                "future_options",
                "memory_context",
                "opportunity_matches",
                "next_actions",
                "signals",
            ],
            "OutcomeUpdateResponse": [
                "execution_score",
                "confidence_delta",
                "memory_id",
                "reputation_event_id",
                "profile_updates",
                "next_recommendation",
            ],
            "VoiceActionRuntimeResponse": [
                "wake_word_detected",
                "inferred_intent",
                "spoken_response",
                "action_graph",
                "experiment_plan",
                "follow_up_questions",
            ],
        },
    )


@app.get("/v1/gateway/routes", response_model=list[ServiceRoute])
async def routes() -> list[ServiceRoute]:
    return get_service().routes()


@app.get("/v1/system/health", response_model=SystemHealthResponse)
async def system_health() -> SystemHealthResponse:
    return await get_service().system_health()


@app.post("/v1/mission/briefing", response_model=MissionBriefingResponse)
async def mission_briefing(request: MissionBriefingRequest) -> MissionBriefingResponse:
    return get_service().mission_briefing(request)


@app.post("/v1/demo/future-os", response_model=DemoRunResponse)
async def future_os_demo(request: DemoRunRequest) -> DemoRunResponse:
    return await get_service().future_os_demo(request)


@app.post("/v1/intelligence/decide", response_model=IntelligenceDecisionResponse)
async def decide(request: IntelligenceDecisionRequest) -> IntelligenceDecisionResponse:
    return await get_service().decide(request)


@app.post("/v1/intelligence/outcomes", response_model=OutcomeUpdateResponse)
async def record_outcome(request: OutcomeUpdateRequest) -> OutcomeUpdateResponse:
    return await get_service().record_outcome(request)


@app.post("/v1/voice/action-runtime", response_model=VoiceActionRuntimeResponse)
async def voice_action_runtime(
    request: VoiceActionRuntimeRequest,
) -> VoiceActionRuntimeResponse:
    return await get_service().voice_action_runtime(request)

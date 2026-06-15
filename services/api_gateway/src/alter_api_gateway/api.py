from __future__ import annotations

from functools import lru_cache

from uuid import UUID

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .schemas import (
    ArchitectureResponse,
    DemoRunRequest,
    DemoRunResponse,
    FutureTwinRequest,
    FutureTwinResponse,
    HealthResponse,
    IntegrationsResponse,
    IntelligenceDecisionRequest,
    IntelligenceDecisionResponse,
    LifeFeedResponse,
    MissionBriefingRequest,
    MissionBriefingResponse,
    OutcomeUpdateRequest,
    OutcomeUpdateResponse,
    ProofCaptureRequest,
    ProofCaptureResponse,
    ServiceRoute,
    SystemHealthResponse,
    UserSettingsPatch,
    UserSettingsResponse,
    VoiceActionRuntimeRequest,
    VoiceActionRuntimeResponse,
    WebResearchRequest,
    WebResearchResponse,
    WebFetchRequest,
    WebFetchResponse,
    MarketplaceSearchRequest,
    MarketplaceSearchResponse,
    OpportunityQueryRequest,
    OpportunityQueryResponse,
    WebResearchHit,
    MarketplaceListing,
    OpportunityHit,
)
from .service import ApiGatewayService, create_api_gateway_service
from . import web_research as web_research_service

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
            "future twin engine",
            "action compiler",
            "evidence engine",
            "opportunity arbitrage engine",
            "proof capture os",
            "daily briefing engine",
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
            "Future Twin compares stated ambition with evidence, predicts trajectory drift, compiles the next action, and surfaces opportunity arbitrage.",
            "Proof Capture OS turns real-world artifacts into memory, reputation, graph edges, daily briefings, and Future Twin deltas.",
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
            "FutureTwinResponse": [
                "trajectory",
                "action",
                "evidence_signals",
                "opportunity_arbitrage",
                "daily_question",
                "model_updates",
            ],
            "ProofCaptureResponse": [
                "evidence_records",
                "graph_nodes",
                "graph_edges",
                "daily_briefing",
                "trust_profile",
                "future_twin_delta",
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


@app.get("/v1/life-feed", response_model=LifeFeedResponse)
async def life_feed(user_id: UUID = Query(...)) -> LifeFeedResponse:
    return get_service().life_feed(user_id)


@app.get("/v1/user/settings", response_model=UserSettingsResponse)
async def user_settings(user_id: UUID = Query(...)) -> UserSettingsResponse:
    return get_service().user_settings(user_id)


@app.patch("/v1/user/settings", response_model=UserSettingsResponse)
async def patch_user_settings(
    patch: UserSettingsPatch,
    user_id: UUID = Query(...),
) -> UserSettingsResponse:
    return get_service().patch_user_settings(user_id, patch)


@app.get("/v1/integrations", response_model=IntegrationsResponse)
async def integrations(user_id: UUID = Query(...)) -> IntegrationsResponse:
    return get_service().integrations(user_id)


@app.post("/v1/demo/future-os", response_model=DemoRunResponse)
async def future_os_demo(request: DemoRunRequest) -> DemoRunResponse:
    return await get_service().future_os_demo(request)


@app.post("/v1/intelligence/decide", response_model=IntelligenceDecisionResponse)
async def decide(request: IntelligenceDecisionRequest) -> IntelligenceDecisionResponse:
    return await get_service().decide(request)


@app.post("/v1/intelligence/outcomes", response_model=OutcomeUpdateResponse)
async def record_outcome(request: OutcomeUpdateRequest) -> OutcomeUpdateResponse:
    return await get_service().record_outcome(request)


@app.post("/v1/intelligence/future-twin", response_model=FutureTwinResponse)
async def future_twin(request: FutureTwinRequest) -> FutureTwinResponse:
    return await get_service().future_twin(request)


@app.post("/v1/proof/capture", response_model=ProofCaptureResponse)
async def capture_proof(request: ProofCaptureRequest) -> ProofCaptureResponse:
    return await get_service().capture_proof(request)


@app.post("/v1/voice/action-runtime", response_model=VoiceActionRuntimeResponse)
async def voice_action_runtime(
    request: VoiceActionRuntimeRequest,
) -> VoiceActionRuntimeResponse:
    return await get_service().voice_action_runtime(request)


@app.post("/v1/web/research", response_model=WebResearchResponse)
async def web_research_route(request: WebResearchRequest) -> WebResearchResponse:
    settings = get_settings()
    rows = await web_research_service.firecrawl_search(
        settings,
        request.query,
        limit=request.limit,
    )
    return WebResearchResponse(
        query=request.query,
        results=[WebResearchHit(**row) for row in rows],
    )


@app.post("/v1/web/fetch", response_model=WebFetchResponse)
async def web_fetch_route(request: WebFetchRequest) -> WebFetchResponse:
    settings = get_settings()
    page = await web_research_service.firecrawl_scrape(settings, request.url)
    return WebFetchResponse(**page)


@app.post("/v1/web/marketplace", response_model=MarketplaceSearchResponse)
async def marketplace_search_route(
    request: MarketplaceSearchRequest,
) -> MarketplaceSearchResponse:
    settings = get_settings()
    rows = await web_research_service.search_marketplace(
        settings,
        query=request.query,
        platform=request.platform,
        limit=request.limit,
    )
    return MarketplaceSearchResponse(
        query=request.query,
        platform=request.platform,
        listings=[MarketplaceListing(**row) for row in rows],
    )


@app.post("/v1/opportunities/query", response_model=OpportunityQueryResponse)
async def opportunities_query_route(
    request: OpportunityQueryRequest,
) -> OpportunityQueryResponse:
    settings = get_settings()
    rows = await web_research_service.query_opportunities(
        settings,
        query=request.query,
        limit=request.limit,
    )
    return OpportunityQueryResponse(
        query=request.query,
        opportunities=[OpportunityHit(**row) for row in rows],
    )

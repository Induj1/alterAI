from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    service: str
    environment: str


class ServiceRoute(BaseModel):
    name: str
    base_url: str
    health_url: str


class ServiceHealth(BaseModel):
    name: str
    base_url: str
    status: str
    latency_ms: int | None = None
    detail: str = ""


class SystemHealthResponse(BaseModel):
    status: str
    services: list[ServiceHealth]
    checked_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class MissionBriefingRequest(BaseModel):
    user_id: UUID = Field(default_factory=uuid4)
    objective: str = Field(min_length=2, max_length=600)
    device_context: str = Field(default="phone", max_length=80)
    include_services: list[str] = Field(default_factory=list, max_length=20)


class MissionBriefingResponse(BaseModel):
    briefing_id: UUID = Field(default_factory=uuid4)
    user_id: UUID
    objective: str
    command_summary: str
    phone_layer: list[str]
    laptop_layer: list[str]
    recommended_sequence: list[str]
    route_targets: list[str]
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class DemoRunRequest(BaseModel):
    user_id: UUID = Field(default_factory=uuid4)
    objective: str = Field(min_length=2, max_length=600)
    device_context: str = Field(default="mission_control", max_length=80)
    profile: dict[str, Any] = Field(default_factory=dict)


class DemoStep(BaseModel):
    name: str
    title: str
    status: str
    summary: str
    latency_ms: int | None = None
    data: dict[str, Any] = Field(default_factory=dict)


class DemoRunResponse(BaseModel):
    demo_id: UUID = Field(default_factory=uuid4)
    user_id: UUID
    objective: str
    headline: str
    executive_summary: str
    steps: list[DemoStep]
    key_metrics: dict[str, str]
    next_actions: list[str]
    risks: list[str]
    opportunities: list[str]
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class IntelligenceDecisionRequest(BaseModel):
    user_id: UUID = Field(default_factory=uuid4)
    question: str = Field(min_length=3, max_length=1000)
    user_profile: dict[str, Any] = Field(default_factory=dict)
    skills: list[str] = Field(default_factory=list, max_length=80)
    goals: list[str] = Field(default_factory=list, max_length=40)
    experience: list[dict[str, Any]] = Field(default_factory=list, max_length=60)
    interests: list[str] = Field(default_factory=list, max_length=80)
    context: dict[str, Any] = Field(default_factory=dict)
    decision_horizon_months: int = Field(default=36, ge=12, le=120)
    write_memory: bool = True


class IntelligenceSignal(BaseModel):
    name: str
    title: str
    status: str
    summary: str
    latency_ms: int | None = None
    data: dict[str, Any] = Field(default_factory=dict)


class FutureOption(BaseModel):
    future_id: str
    name: str
    thesis: str
    success_probability: float = Field(ge=0.0, le=1.0)
    opportunity_score: float = Field(ge=0.0, le=100.0)
    risk_score: float = Field(ge=0.0, le=100.0)


class ExperimentPlan(BaseModel):
    experiment_id: UUID = Field(default_factory=uuid4)
    action: str = Field(min_length=2, max_length=280)
    why_it_matters: str = Field(min_length=2, max_length=600)
    deadline: str = Field(min_length=2, max_length=80)
    success_metric: str = Field(min_length=2, max_length=280)


class IntelligenceDecisionResponse(BaseModel):
    decision_id: UUID = Field(default_factory=uuid4)
    user_id: UUID
    question: str
    recommendation: str
    confidence_score: float = Field(ge=0.0, le=1.0)
    decision_summary: str
    recommended_future: str
    experiment_plan: ExperimentPlan
    future_options: list[FutureOption]
    memory_context: list[str]
    opportunity_matches: list[str]
    next_actions: list[str]
    risks: list[str]
    opportunities: list[str]
    signals: list[IntelligenceSignal]
    created_memory_id: UUID | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class OutcomeUpdateRequest(BaseModel):
    user_id: UUID
    decision_id: UUID | None = None
    question: str = Field(min_length=3, max_length=1000)
    experiment_plan: ExperimentPlan
    did_it: bool
    what_happened: str = Field(min_length=2, max_length=1500)
    what_learned: str = Field(min_length=2, max_length=1500)
    success_metric_result: str = Field(min_length=2, max_length=600)
    outcome_score: float = Field(ge=0.0, le=1.0)


class OutcomeUpdateResponse(BaseModel):
    outcome_id: UUID = Field(default_factory=uuid4)
    user_id: UUID
    decision_id: UUID | None = None
    execution_score: float = Field(ge=0.0, le=100.0)
    confidence_delta: float = Field(ge=-1.0, le=1.0)
    memory_id: UUID | None = None
    reputation_event_id: UUID | None = None
    reputation_score: int | None = None
    trust_level: str = ""
    profile_updates: list[str]
    next_recommendation: str
    memory_summary: str
    signals: list[IntelligenceSignal]
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class VoiceActionRuntimeRequest(BaseModel):
    user_id: UUID = Field(default_factory=uuid4)
    transcript: str = Field(min_length=1, max_length=4000)
    locale: str = Field(default="en-US", min_length=2, max_length=16)
    device_surface: str = Field(default="phone", max_length=24)
    user_profile: dict[str, Any] = Field(default_factory=dict)
    skills: list[str] = Field(default_factory=list, max_length=80)
    goals: list[str] = Field(default_factory=list, max_length=40)
    interests: list[str] = Field(default_factory=list, max_length=80)
    context: dict[str, Any] = Field(default_factory=dict)


class VoiceActionRuntimeResponse(BaseModel):
    runtime_id: UUID = Field(default_factory=uuid4)
    user_id: UUID
    transcript: str
    normalized_text: str
    wake_word_detected: bool
    inferred_intent: str
    intent_confidence: float = Field(ge=0.0, le=1.0)
    spoken_response: str
    display_response: str
    action_graph: list[str]
    experiment_plan: ExperimentPlan | None = None
    next_actions: list[str]
    follow_up_questions: list[str]
    decision_report: IntelligenceDecisionResponse | None = None
    signals: list[IntelligenceSignal]
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class ArchitectureResponse(BaseModel):
    service: str
    components: list[str]
    data_flow: list[str]
    output_contract: dict[str, list[str]]

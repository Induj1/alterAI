from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    gateway_env: str = Field(default="local", alias="ALTER_GATEWAY_ENV")
    multilingual_provider: str = Field(default="sarvam", alias="ALTER_MULTILINGUAL_PROVIDER")
    default_language_code: str = Field(default="en-IN", alias="ALTER_DEFAULT_LANGUAGE_CODE")
    sarvam_api_key: str = Field(default="", alias="SARVAM_API_KEY")
    sarvam_api_base_url: str = Field(
        default="https://api.sarvam.ai",
        alias="SARVAM_API_BASE_URL",
    )
    sarvam_tts_model: str = Field(default="bulbul:v2", alias="ALTER_SARVAM_TTS_MODEL")
    sarvam_stt_model: str = Field(default="saarika:v2.5", alias="ALTER_SARVAM_STT_MODEL")
    voice_gateway_url: str = Field(default="http://localhost:8070", alias="ALTER_VOICE_GATEWAY_URL")
    clone_council_url: str = Field(default="http://localhost:8080", alias="ALTER_CLONE_COUNCIL_URL")
    future_simulation_url: str = Field(
        default="http://localhost:8090",
        alias="ALTER_FUTURE_SIMULATION_URL",
    )
    memory_system_url: str = Field(default="http://localhost:8100", alias="ALTER_MEMORY_SYSTEM_URL")
    opportunity_engine_url: str = Field(
        default="http://localhost:8110",
        alias="ALTER_OPPORTUNITY_ENGINE_URL",
    )
    social_graph_url: str = Field(default="http://localhost:8120", alias="ALTER_SOCIAL_GRAPH_URL")
    alter_lens_url: str = Field(default="http://localhost:8130", alias="ALTER_LENS_URL")
    reputation_engine_url: str = Field(
        default="http://localhost:8140",
        alias="ALTER_REPUTATION_ENGINE_URL",
    )
    officekit_url: str = Field(default="http://localhost:8150", alias="ALTER_OFFICEKIT_URL")
    firecrawl_api_key: str = Field(default="", alias="ALTER_FIRECRAWL_API_KEY")
    firecrawl_base_url: str = Field(
        default="https://api.firecrawl.dev/v1",
        alias="ALTER_FIRECRAWL_BASE_URL",
    )
    web_research_timeout_seconds: float = Field(default=20.0, alias="ALTER_WEB_RESEARCH_TIMEOUT")

    def service_urls(self) -> dict[str, str]:
        return {
            "voice_gateway": self.voice_gateway_url,
            "clone_council": self.clone_council_url,
            "future_simulation": self.future_simulation_url,
            "memory_system": self.memory_system_url,
            "opportunity_engine": self.opportunity_engine_url,
            "social_graph": self.social_graph_url,
            "alter_lens": self.alter_lens_url,
            "reputation_engine": self.reputation_engine_url,
            "officekit": self.officekit_url,
        }


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()

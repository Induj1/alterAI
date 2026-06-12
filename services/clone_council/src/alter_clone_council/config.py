from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for the Clone Council service."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="ALTER_",
        extra="ignore",
    )

    clone_council_env: str = Field(default="local", alias="ALTER_CLONE_COUNCIL_ENV")
    gemini_model: str = Field(default="gemini-2.5-pro", alias="ALTER_GEMINI_MODEL")
    gemini_temperature: float = Field(default=0.25, ge=0.0, le=2.0)
    gemini_thinking_budget: int = Field(default=2048, ge=-1)
    gemini_max_retries: int = Field(default=2, ge=0, le=5)
    request_timeout_seconds: int = Field(default=90, ge=10, le=240)
    max_challenges_per_agent: int = Field(default=2, ge=1, le=5)
    expose_agent_prompts: bool = Field(default=False)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


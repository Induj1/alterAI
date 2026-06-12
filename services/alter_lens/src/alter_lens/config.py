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

    alter_lens_env: str = Field(default="local", alias="ALTER_LENS_ENV")
    alter_lens_gemini_model: str = Field(
        default="gemini-2.5-flash",
        alias="ALTER_LENS_GEMINI_MODEL",
    )
    google_api_key: str | None = Field(default=None, alias="GOOGLE_API_KEY")
    alter_lens_max_upload_mb: int = Field(default=12, alias="ALTER_LENS_MAX_UPLOAD_MB")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()

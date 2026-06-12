from __future__ import annotations

from uuid import UUID

from .config import Settings, get_settings
from .repository import InMemoryMemoryRepository, MemoryRepository
from .schemas import (
    MemoryContextBlock,
    MemoryItem,
    MemoryItemCreate,
    MemoryItemUpdate,
    MemoryRetrieveRequest,
    MemoryRetrieveResponse,
    MemorySearchRequest,
    MemorySearchResponse,
    PromoteShortTermRequest,
    ShortTermMemory,
    ShortTermMemoryCreate,
    TimelineResponse,
)


class MemoryNotFoundError(LookupError):
    pass


class MemoryService:
    def __init__(self, *, settings: Settings, repository: MemoryRepository) -> None:
        self._settings = settings
        self._repository = repository

    def create_memory(self, payload: MemoryItemCreate) -> MemoryItem:
        return self._repository.create_memory(payload)

    def get_memory(self, user_id: UUID, memory_id: UUID) -> MemoryItem:
        memory = self._repository.get_memory(user_id, memory_id)
        if memory is None:
            raise MemoryNotFoundError(str(memory_id))
        return memory

    def update_memory(
        self,
        user_id: UUID,
        memory_id: UUID,
        payload: MemoryItemUpdate,
    ) -> MemoryItem:
        memory = self._repository.update_memory(user_id, memory_id, payload)
        if memory is None:
            raise MemoryNotFoundError(str(memory_id))
        return memory

    def archive_memory(self, user_id: UUID, memory_id: UUID) -> MemoryItem:
        memory = self._repository.archive_memory(user_id, memory_id)
        if memory is None:
            raise MemoryNotFoundError(str(memory_id))
        return memory

    def search(self, request: MemorySearchRequest) -> MemorySearchResponse:
        return MemorySearchResponse(
            query=request.query,
            hits=self._repository.search(request),
        )

    def retrieve(self, request: MemoryRetrieveRequest) -> MemoryRetrieveResponse:
        search_request = MemorySearchRequest(
            user_id=request.user_id,
            query=request.task,
            query_embedding=request.query_embedding,
            memory_types=request.memory_types,
            include_short_term=True,
            limit=request.limit,
        )
        hits = self._repository.search(search_request)
        context = [
            MemoryContextBlock(
                memory_id=hit.memory.id,
                memory_type=hit.memory.memory_type,
                title=hit.memory.title,
                summary=hit.memory.summary,
                content=hit.memory.content,
                relevance=hit.similarity,
                confidence=hit.memory.confidence,
                importance=hit.memory.importance,
            )
            for hit in hits
            if request.include_private or hit.memory.privacy != "private"
        ]
        return MemoryRetrieveResponse(
            task=request.task,
            context=context,
            retrieval_notes=[
                "Ranked by semantic similarity when embeddings are supplied.",
                "Falls back to lexical overlap, importance, and recency without embeddings.",
            ],
        )

    def create_short_term(self, payload: ShortTermMemoryCreate) -> ShortTermMemory:
        memory = ShortTermMemory.from_create(
            payload,
            default_ttl_minutes=self._settings.short_term_ttl_minutes,
        )
        return self._repository.create_short_term(memory)

    def promote_short_term(self, payload: PromoteShortTermRequest) -> MemoryItem:
        short_term = self._repository.get_short_term(
            payload.user_id,
            payload.short_term_memory_id,
        )
        if short_term is None:
            raise MemoryNotFoundError(str(payload.short_term_memory_id))
        memory = self.create_memory(
            MemoryItemCreate(
                user_id=payload.user_id,
                memory_type=payload.memory_type,
                title=payload.title,
                summary=short_term.summary,
                content=str(short_term.value),
                source="short_term_promotion",
                confidence=payload.confidence,
                importance=payload.importance,
                metadata={
                    **payload.metadata,
                    "short_term_memory_id": str(short_term.id),
                    "key": short_term.key,
                },
            )
        )
        self._repository.mark_promoted(payload.user_id, short_term.id, memory.id)
        return memory

    def timeline(self, user_id: UUID, limit: int) -> TimelineResponse:
        return TimelineResponse(
            user_id=user_id,
            memories=self._repository.recent(user_id, limit),
        )


def create_memory_service(
    *,
    settings: Settings | None = None,
    repository: MemoryRepository | None = None,
) -> MemoryService:
    return MemoryService(
        settings=settings or get_settings(),
        repository=repository or InMemoryMemoryRepository(),
    )


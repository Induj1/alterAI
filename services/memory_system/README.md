# ALTER Memory System

Lifelong user memory for skills, projects, goals, conversations, opportunities, decisions, mentors, friends, and learning progress.

## High-Level Architecture

```mermaid
flowchart TB
  Client["Mobile App / Agent Services"] --> API["FastAPI Memory API"]
  API --> Service["Memory Service"]
  Service --> Policy["Privacy + Retention Policy"]
  Service --> Retriever["Memory Retriever"]
  Service --> Updater["Memory Updater"]
  Service --> STM["Short-Term Memory Manager"]
  Service --> LTM["Long-Term Memory Manager"]

  Retriever --> Postgres["PostgreSQL"]
  Retriever --> Pgvector["pgvector Semantic Index"]
  Updater --> Postgres
  STM --> Postgres
  LTM --> Postgres
  Pgvector --> Postgres
```

## Data Flow

```mermaid
sequenceDiagram
  participant App as Client
  participant API as FastAPI
  participant S as Memory Service
  participant DB as PostgreSQL
  participant V as pgvector

  App->>API: Create memory / short-term note
  API->>S: Validate and classify
  S->>DB: Store canonical memory
  S->>V: Store embedding when available
  App->>API: Search or retrieve context
  API->>S: Build retrieval query
  S->>V: Semantic search
  S->>DB: Fetch details and relationships
  S-->>API: Ranked memory context
  API-->>App: Structured JSON
```

## Storage Strategy

```mermaid
flowchart LR
  STM["Short-Term Memory\nsession scoped, expires"] --> Promote["Promotion Rules"]
  Promote --> LTM["Long-Term Memory\ncanonical memory_items"]
  LTM --> Embeddings["memory_embeddings\npgvector"]
  LTM --> Details["Typed Detail Tables"]
  LTM --> Edges["memory_relationships"]
```

Short-term memory stores volatile session facts and working context with TTL. Long-term memory stores durable facts, decisions, relationships, and user history. Promotion links a short-term item to a durable `memory_items` row.

## APIs

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/v1/memory/items` | Create long-term memory |
| `GET` | `/v1/memory/items/{memory_id}` | Fetch memory |
| `PATCH` | `/v1/memory/items/{memory_id}` | Update memory |
| `POST` | `/v1/memory/items/{memory_id}/archive` | Archive memory |
| `POST` | `/v1/memory/search` | Semantic or lexical memory search |
| `POST` | `/v1/memory/retrieve` | Retrieve agent-ready memory context |
| `POST` | `/v1/memory/short-term` | Create short-term memory |
| `POST` | `/v1/memory/short-term/promote` | Promote short-term memory to long-term |
| `GET` | `/v1/memory/users/{user_id}/timeline` | Recent durable memories |
| `GET` | `/v1/memory/architecture` | Service architecture summary |

## Run

```bash
cd services/memory_system
python -m venv .venv
.venv\Scripts\activate
pip install -e ".[dev]"
uvicorn alter_memory_system.api:app --reload --port 8100
```

Apply migrations to PostgreSQL:

```bash
psql "$ALTER_DATABASE_URL" -f migrations/001_extensions.sql
psql "$ALTER_DATABASE_URL" -f migrations/002_memory_schema.sql
```


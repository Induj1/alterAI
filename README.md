# ALTER

ALTER is a mobile-first Flutter application for a voice-first AI Future Operating System.

## Stack

- Flutter with Material 3
- Riverpod for application state
- go_router for route orchestration
- Clean Architecture boundaries: domain, data, application, presentation
- Glassmorphism UI inspired by Apple Vision Pro, Linear, Anthropic, and Arc Browser

## Screens

- Mission Control
- Splash
- Onboarding
- Voice Assistant
- Clone Council
- Future Simulator
- Opportunity Radar
- Social Graph
- Reputation Dashboard
- Alter Lens
- Settings

## Run

```bash
flutter pub get
flutter run
```

If this repository was not created with `flutter create`, run `flutter create .`
once to generate native platform folders, then keep the existing `lib`, `test`,
`pubspec.yaml`, and `analysis_options.yaml` files.

## Architecture

```text
lib/
  src/
    app/                  App composition, router, global state, theme
    core/                 Shared theme, utilities, reusable UI primitives
    data/                 Repository implementations and adapters
    domain/               Entities and repository contracts
    features/             Feature presentation and application providers
```

## Backend Services

```text
  services/
  api_gateway/            Client-facing gateway and mission edge service
  voice_gateway/          Wake phrase and voice intent routing service
  clone_council/          LangGraph Clone Council debate service
  future_simulation/      Structured Future Simulation Engine
  memory_system/          PostgreSQL and pgvector lifelong memory service
  opportunity_engine/     Crawl, rank, and recommend opportunity service
  social_graph/           Neo4j relationship intelligence service
  alter_lens/             OpenAI vision camera intelligence service
  reputation_engine/      Trust ledger and reputation scoring service
  officekit/              Office artifact briefing and action extraction
```

The Clone Council service exposes a FastAPI endpoint at
`POST /v1/clone-council/debate` and uses OpenAI structured outputs in production.

The Future Simulation service exposes `POST /v1/future-simulation/simulate`
and returns strict JSON for Future A, Future B, and Future C.

The Memory System exposes `POST /v1/memory/items`, `/search`, `/retrieve`,
and short-term memory promotion APIs backed by PostgreSQL and pgvector schema.

The Opportunity Engine exposes `POST /v1/opportunities/pipeline` for
crawl -> normalize -> categorize -> rank -> recommend workflows.

The Social Graph Engine exposes Neo4j-backed APIs for mutual connections,
career paths, recruiter discovery, mentor discovery, and team formation.

The Alter Lens service exposes `POST /v1/alter-lens/analyze` for camera
intelligence over resumes, startup decks, event posters, research papers, and
products.

The Voice Gateway exposes `POST /v1/voice/session` for wake phrase and
transcript intent routing.

The Reputation Engine exposes `POST /v1/reputation/events` and
`GET /v1/reputation/users/{user_id}/score` for trust scoring.

OfficeKit exposes `POST /v1/officekit/briefing` for meeting, email, document,
and slide mission briefings.

The API Gateway exposes `/v1/gateway/routes`, `/v1/system/health`, and
`POST /v1/mission/briefing`.

## Local Backend

```bash
docker compose up --build
```

Gateway URL: `http://localhost:8060`

## Launch Blueprint

- [ALTER Unicorn Launch Blueprint](docs/alter_unicorn_launch_blueprint.md)
- [Mission Control Frontend Architecture](docs/mission_control_frontend.md)
- [Alter Lens Flow](docs/alter_lens.md)
- [NFC Networking](docs/nfc_networking.md)

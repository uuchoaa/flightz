# Flightz

Round-trip flight search over Google Flights' private shopping endpoint - no official API, no keys - built on Clean Architecture, with the search narrating every pipeline step live over Server-Sent Events.

<img width="1341" height="1074" alt="flightz-voos" src="https://github.com/user-attachments/assets/e7b97fd4-777e-4c91-97fc-8de1d75dbb3b" />

<img width="1341" height="1074" alt="fligthz-logs" src="https://github.com/user-attachments/assets/65377c69-b285-461d-8a8b-93fd4f4ee5bf" />

<img width="1341" height="1074" alt="flightz-ajustes" src="https://github.com/user-attachments/assets/e5f8bd0b-fd1d-4773-9ce1-8c9383b72872" />


## Highlights

* Errors as values: No exception crosses a layer boundary; the dependency rule is an executable test (`test/architecture_test.rb`).
* Shape-resilient parser: Walks Google's response tree collecting nodes by flight-info signature instead of hard-coded indexes (`lib/google_flights/parser.rb`).
* Degrade-only tokens: Anti-bot tokens are read off headless Chrome; the store resolves memory → disk → fresh → stale → HAR seed and never raises (`lib/google_flights/tokens.rb`).
* Self-narrating search: One `log` callback drives the SSE console, the audited ledger (`/logs`), and `smoke.rb`.
* Phlex views, policed kit: The agnostic kit never says a domain word; the app tier speaks only the kit - both enforced by tests.
* One process: SQLite for everything; Solid Queue inside Puma.

Full pipeline and wire-format notes: `docs/architecture.md`.

## Running

```bash
bundle install
bin/rails server        # http://localhost:3000
```

Or without a server:

```bash
ruby smoke.rb JFK LAX 2026-10-26 2026-11-02
```

Surfaces: `/` (form + live console), `GET /search/stream` (SSE), `GET /api/queries/flights_search` (JSON), `/logs`, `/settings`.

## Testing

```bash
bin/rails test
```

Parser tests replay a captured Google response; everything runs offline.

## Deploy

Single-container [Kamal](https://kamal-deploy.org) deploy (`config/deploy.yml`): `bin/kamal setup`, then `bin/kamal deploy`. Point `image:`/`servers:` at your own registry and host; Chrome must be in the image for live token extraction.

## Known limitation: prices

Flights, schedules and ordering match the web UI exactly, but prices read higher per airline: our `f.req` requests a fare basis excluding Basic Economy, unlike the web default. Verified as a payload flag, not geo/fingerprint. See `docs/architecture.md`.

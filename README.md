# Flightz

Round-trip flight search over Google Flights' **private** shopping endpoint —
no official API, no keys — ported into a Clean Architecture skeleton where the
rings are directories and every domain outcome is a value, not an exception.
The search runs live and **narrates every step of its pipeline to the screen**
over Server-Sent Events.

A showcase: the interesting parts are how the layers are kept honest, how a
brittle reverse-engineered endpoint is made resilient, and how a long
server-side operation is made legible to the user in real time.

## Highlights

- **Errors as values, enforced.** No exception crosses a layer boundary to
  signal a domain outcome; `Result`/`{ error:, details: }` do. The dependency
  rule (entities → use cases → delivery, inward only) is an *executable* test
  (`test/architecture_test.rb`), not a convention.
- **A reverse-engineered client that survives route shape.** Google returns
  best/other itineraries at route-dependent depths. Instead of hard-coding
  indexes, `GoogleFlights::Parser` walks the tree and collects every node
  wearing the flight-info signature (IATA endpoints, integer duration, cents
  price) — so a 34-flight domestic route and a 1-flight international route
  both parse (`lib/google_flights/parser.rb`).
- **Live token refresh, degrade-only.** The anti-bot tokens expire;
  `TokenExtractor` drives headless Chrome (Ferrum) and reads them off the
  `GetShoppingResults` request Google's own page fires — no scraping. The
  store resolves memory → disk cache → fresh extraction → stale cache → a
  captured HAR seed, and **never raises** (`lib/google_flights/tokens.rb`).
- **The search narrates itself.** A single `log` callback threads through the
  whole pipeline; `FlightsStreamController` (`ActionController::Live`) streams
  each step as an SSE event and the Stimulus `stream` controller renders a
  running/done console, then injects the offers. The same callback drives
  `smoke.rb` on the CLI.
- **The ledger is the log viewer.** Every search is audited into the
  write-side ledger: an `info` summary with each pipeline step as a `debug`
  child (parent/child hierarchy), filterable by level, reusing the very same
  step translations the live console shows.
- **Views are Ruby, and the kit is policed.** Phlex components with a strict
  split: the agnostic *kit* never says a domain word, the *app tier* speaks
  only the kit (no native tags, no CSS classes) — both laws are tests.
- **One process, local-first.** SQLite for everything (primary + Solid
  Queue/Cache/Cable); Solid Queue runs inside Puma. `bin/rails server` is the
  whole stack.

## Architecture at a glance

```
lib/google_flights/     # infra seam: http · payload · parser · tokens · extractor · static
app/use_cases/          # ring 2: flights/queries/search, settings, ledger/queries/events
app/presenters/         # ring 3: flight · event (formatting)
app/views/ app/components/ app/controllers/   # ring 4: Phlex screens, kit, SSE + API
```

Full pipeline, wire-format notes, and index map: **`docs/architecture.md`**.

## Running

```bash
bundle install
bin/rails server        # http://localhost:3000
```

The form lands pre-filled with a default route but does **not** search on its
own. Submit to run: the console narrates, then the offers land in a table.

## Try it without a server

```bash
ruby smoke.rb                          # GRU -> REC, a month out
ruby smoke.rb JFK LAX 2026-10-26 2026-11-02
```

One real search through the whole seam, printing the narrated steps and the
offers.

## Surfaces

- **Screen** — `/` (`Views::FlightsScreen`): form + live console.
- **SSE stream** — `GET /search/stream?origin=&destination=&departure_date=&return_date=`:
  `event: step` lines, then a final `event: done` with the rendered offers.
- **JSON API** — `GET /api/queries/flights_search?origin=…`: the raw
  `{ best_flights: [...] }` from the ring-2 query.
- **Logs** — `/logs`: the audited search/command ledger, filterable by level.
- **Settings** — `/settings`: locale, saved as a real `update_settings`
  command down the W (ledger row → job → confirm).

## Testing

```bash
bin/rails test
```

Parser tests replay a captured Google response
(`test/fixtures/files/google_flights/`); the token store, payload, query,
stream and screens are covered without touching the network. The architecture
and kit laws run as tests too.

## Deploy

Single-container [Kamal](https://kamal-deploy.org) deploy (`config/deploy.yml`,
`Dockerfile`): SQLite on a persistent volume, Solid Queue inside Puma
(`SOLID_QUEUE_IN_PUMA=1`) so there is no separate job host, TLS via Let's
Encrypt. Target in the repo is a Hetzner box addressed through sslip.io (no
domain needed).

```bash
bin/kamal setup         # first time
bin/kamal deploy        # subsequent
```

Point `image:`/`servers:` at your own registry and host first. Chrome must be
present in the image for live token extraction; otherwise the client falls
back to the HAR seed until it expires.

## Roadmap

- **Fare parity** — align the `f.req` fare flag so prices match the web
  (see the limitation below); needs the browser's real `GetShoppingResults`
  body captured and diffed against `Payload.build`.
- **Search options** — one-way and multi-city, cabin class, passenger counts,
  metro/city search (`CITY_TYPE`), stops/airline filters.
- **Price history** — the ledger already records searches; promote that into a
  first-class saved-search + price-tracking domain, with the Solid Cable
  socket pushing updates (the channel is already wired).
- **Result UX** — sorting, pagination, segment/leg detail expansion.
- **Token hardening** — proxy pool and fingerprint rotation for production
  scale; a background refresh so the first request is never cold.

## Known limitation: prices

Flights, schedules, durations, stops, airlines and ordering match the Google
Flights web UI **exactly**. Prices read higher and diverge per airline
(JetBlue ~2.2×, Delta ~1.1×): the web default is "Economy (include Basic)" and
our `f.req` requests a fare basis that excludes Basic Economy, whose discount
varies sharply by carrier. Verified with a clean-fingerprint browser
(Camoufox) from the same machine/IP reproducing the web prices, which rules
out geo/fingerprint pricing — it is a payload flag. See `docs/architecture.md`.

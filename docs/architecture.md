# Flights domain architecture

The flights domain reuses the skeleton's Clean Architecture (see the root
`architecture.md`): rings are directories under `app/`, the dependency rule
points inward, and every domain outcome is a value — no exception crosses a
layer boundary. Reads are V-shaped (query → presenter → screen). There is no
W here yet: search is a pure read.

## The rings, for this domain

```
lib/google_flights/            # infrastructure seam (outside the rings)
  google_flights.rb            #   module entry: GoogleFlights.search(..., log:)
  http.rb                      #   real backend: f.req POST + gunzip
  static.rb                    #   test backend: canned results
  payload.rb                   #   builds the f.req nested-array body
  parser.rb                    #   decodes the wire format -> flight hashes
  tokens.rb                    #   anti-bot token store (memory/disk/seed)
  token_extractor.rb           #   headless Chrome (Ferrum) token capture

app/use_cases/flights/         # ring 2 — the domain
  queries/search.rb            #   validate criteria -> call the seam

app/presenters/
  flight_presenter.rb          # ring 3 — one offer, formatted for the table

app/views/
  flights_screen.rb            # ring 4 — form + live console
  flights_results.rb           #          offers fragment (streamed in)
app/components/stream.rb       # ring 4 — generic SSE console (kit)
app/controllers/
  flights_stream_controller.rb # ring 4 — SSE delivery (ActionController::Live)
  app_shell_controller.rb      #          the screen (index)
  api/queries_controller.rb    #          the JSON read side (unchanged)
```

The domain (`Flights::Queries::Search`) knows nothing of HTTP, Ferrum, or
`Net::HTTP`; it speaks only to the `GoogleFlights` seam. The seam is swapped
for `GoogleFlights::Static` in tests (`test_helper.rb`).

## The search pipeline

`GoogleFlights.search` threads an optional `log` callback — `call(step_key,
**data)` — through every stage. `FlightsStreamController` passes a callback
that writes each step as an SSE `event: step`; `smoke.rb` passes one that
prints. With no callback the pipeline is silent. Steps, in order:

```
validate                     Search: criteria shape (IATA, YYYY-MM-DD)
tokens_resolve               Http: ask the token store
  tokens_cache_hit/miss        memory/disk cache lookup
  tokens_fresh                 cache still within TTL, or
  tokens_refresh               -> TokenExtractor
    browser_launch/navigate    headless Chrome to google.com/travel/flights
    browser_wait_request       watch traffic for GetShoppingResults
    browser_extracted          read tokens off Google's own request, or
    browser_no_tokens/error    -> fall back
  tokens_seed                  last resort: the captured HAR seed
payload_build                Payload: the f.req nested array (both legs)
http_send / http_response    POST to FlightsFrontendService, HTTP status
decode_gzip                  gunzip the body
parse_envelope / parse_done  Parser: locate payload, collect flights
```

Any stage may short-circuit to an error value (`network_error`, `http_error`,
`parse_error`, `invalid`); the screen renders it via `flights.error.*`.

## Reverse-engineered wire format

Reconstructed from a captured HAR; positional and brittle by nature.

**Request** (`Payload.build`): `f.req=<url-encoded JSON>` where the JSON is
`[null, "<stringified array>"]`. The inner array carries passenger/cabin
flags and, at index 13 of its second element, the two legs. Each leg is
`[[[[origin, 0]]], [[[dest, 0]]], null, 0, …, "YYYY-MM-DD", …, 3]` — the `0`
is `AIRPORT_TYPE` (4 would be a city/metro), the trailing `3` the stops
filter.

**Response** (`Parser`): an anti-JSON prefix `)]}'` then length-prefixed JSON
chunks. The largest chunk is the shopping payload; its element `[0][2]` is a
*stringified* JSON array whose sections hold the itinerary lists (best at
section 2, the rest at 3), nested at route-dependent depths.

Rather than hard-code indexes, `Parser` walks the tree and collects every
node wearing the flight-info signature: IATA endpoints at `[3]`/`[6]`, an
integer duration at `[9]`, and a cents price at `[22][7]`. Segments carry
airports but no price, so they never match and recursion never double-counts.
Pre-order preserves Google's ranking; a final `dedup` drops the
best-list/full-list overlap. This is what makes a 34-flight domestic route and
a 1-flight international route both parse correctly.

## Tokens

`GoogleFlights::Tokens` is a lazy, thread-safe store for the five values the
endpoint demands (`X-Goog-BatchExecute-Bgr`, `X-Goog-Ext-259736195-Jspb`,
`X-Browser-Validation`, `f.sid`, `bl`). Resolution order: memory → disk cache
(`tmp/google_flights_tokens.json`, fresh within a 24h TTL) → `TokenExtractor`
(headless Chrome) → stale cache → the `SEED` captured from a HAR. It never
raises; the worst case is expired tokens and an HTTP error value upstream.

`TokenExtractor` opens Google Flights in headless Chrome and reads the tokens
off the `GetShoppingResults` request the page fires on its own — no scraping
of the DOM, no reconstruction.

## The logs ledger

The write-side ledger (`Command`) doubles as the app's log viewer. Searches
are reads, but for the showcase each completed search is audited into the
ledger: an `info` summary row (`name: "search"`, criteria as payload, flight
count or error code as result) with every pipeline step recorded as a `debug`
child (`parent_id` set, the step key as name, the step data as payload). The
`FlightsStreamController` writes these directly — a read, audited, not routed
through the W — guarded so a ledger failure never breaks the search.

The logs screen filters by level (`all` / `info` / `debug`, default `info`)
via `Tabs`; debug rows reuse the `flights.step.*` translations, so the ledger
shows the same narration the live console does.

## Known limitation: fare basis

Times, durations, stops, airlines and ordering match the web UI exactly, but
prices read higher and diverge per airline (JetBlue ~2.2×, Delta ~1.1×). The
web default is "Economy (include Basic)"; our `f.req` requests a fare basis
that excludes Basic Economy, whose discount varies sharply by carrier — hence
the per-airline spread. Verified with a clean-fingerprint browser (Camoufox)
from the same machine/IP reproducing the web prices, which rules out
geo/fingerprint pricing. The fix is a payload flag; pinning it down needs the
browser's real `GetShoppingResults` body captured and diffed against
`Payload.build`. `GetShoppingResults` only fires on interaction (the results
page itself is server-rendered), so the capture must be triggered by a filter
click, not a bare page load.

# app/use_cases — ring 2

The domain: application-specific rules. Use cases orchestrate entities and the
`GoogleFlights`/`Infer` seams, and return **values** — `Result` for writes,
plain as_json-ready hashes for reads. No controller, ActionCable, or job may
be named here (architecture test).

- `registry.rb` — the input boundary: an explicit allowlist mapping command
  and query names to classes. Controllers never `const_get` user input; they
  look it up here. Completeness is a test.
- `result.rb` — the write outcome value: `Result.ok` / `Result.err`; pattern-
  matchable, `as_json`-ready. Raising is reserved for bugs.
- `flights/queries/search.rb` — validate criteria, call the seam, thread the
  `log` callback that narrates the pipeline.
- `settings/` — `defaults`, `update_settings` (a real command), and the
  settings query.
- `ledger/queries/events.rb` — the read behind the Logs screen: every command
  and search with its outcome, newest first, filterable by status/name/level.

Naming stays semantic: a file at `flights/queries/search.rb` defines
`Flights::Queries::Search`, not `UseCases::…` — the directory marks the ring.

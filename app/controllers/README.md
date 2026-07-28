# app/controllers — ring 4 (delivery)

The web edge: thin. Controllers dispatch to ring-2 use cases through the
`Registry`, wrap reads in presenters, and render Phlex screens. They hold no
domain logic.

- `app_shell_controller.rb` — the screens: `index` (flights form, pre-filled,
  search deferred to SSE), `logs` (level-filtered ledger), `settings`.
- `flights_stream_controller.rb` — the SSE delivery (`ActionController::Live`):
  runs the search with a `log` callback that streams each step, then the
  rendered offers; also audits the search into the ledger.
- `api/` — the whole programmatic surface: `commands` (the W: shape-check →
  ledger row → job → 202) and `queries` (the V: dispatch to a query object).
- `application_controller.rb` — sets the locale from settings around every
  action.

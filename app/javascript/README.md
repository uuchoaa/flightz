# app/javascript — ring 4 (delivery)

The thin client, served by importmap (no build step, no node runtime). Stimulus
controllers wire DOM events to the HTTP surfaces; there is no client-side domain
logic.

- `controllers/stream_controller.js` — opens the search SSE stream, renders the
  running/done step console, injects the offers.
- `controllers/command_controller.js`, `form_controller.js` — trigger a single
  registry command (the W) and toast the outcome.
- `controllers/search_controller.js` — client-side quick filter over rendered
  rows; `toast_controller.js` — the snackbar.
- `lib/commands.js` — the client side of the W: POST `/api/commands`, poll the
  ledger until the row leaves `pending`, plus `t()` i18n and `refreshPage()`.

# app/presenters — ring 3

Interface adapters: they turn ring-2 read data into exactly what a screen
needs — formatting, labels, badges — so views hold no formatting logic and use
cases hold no presentation. They may use kit components (e.g. `Badge`) but
know nothing of HTTP.

- `flight_presenter.rb` — one offer for the results table: carrier, local
  times, `6h24`-style duration, stops badge, BRL price.
- `event_presenter.rb` — one ledger row for the Logs table: status/level
  badges, child indentation, and — for debug rows — the same localized step
  narration the live console shows.

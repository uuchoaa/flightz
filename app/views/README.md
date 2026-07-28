# app/views — ring 4 (the app tier)

Phlex screens in pure Ruby (`Views::…`), plus the ERB layouts and PWA files.
The **app tier** obeys one law (an architecture test): it speaks *only* the
kit — no native HTML tags, no CSS classes, no attribute splats. Domain
vocabulary is allowed here; layout primitives come from `app/components`.

- `base.rb` — the screen base: declares which Stimulus controllers the shell
  carries and builds the top-nav entries.
- `flights_screen.rb` — the form + the live `Stream` console.
- `flights_results.rb` — the offers fragment, rendered on its own so the SSE
  controller can inject it when the search resolves.
- `logs_screen.rb` — the ledger table with the level filter tabs.
- `settings_screen.rb` — the settings form (one `update_settings` command).
- `layouts/`, `pwa/` — the HTML shell, manifest, service worker.

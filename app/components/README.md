# app/components — ring 4 (the kit)

The agnostic view kit: Phlex components that are pure layout/interaction
vocabulary. The law (an architecture test): **the kit never says a domain
word** — not even in a comment. Screens compose these; screens never write raw
HTML. The one exception is `labels.rb`, a domain-aware helper explicitly
listed as such.

Primitives include `Stack`, `Row`, `Grid`, `Card`, `Table`, `Badge`,
`Button`, `Fab`, `Text`, `Icon`, form inputs, `Segmented`, `Menu`, `Drawer`,
`Toast`. App-specific-but-still-generic additions from this build:

- `stream.rb` — a live SSE console: opens an EventSource, renders one
  running/done line per server step, injects the final fragment.
- `tabs.rb` — a segmented row of link tabs (GET navigation) for filters.
- `top_nav.rb` — the horizontal brand + destination bar.

`base.rb` is the Phlex base (route/`t` helpers, the `wire`/`on`/`target`
data-attribute contracts the Stimulus controllers read).

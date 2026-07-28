# app/assets — ring 4 (delivery)

Static assets and the CSS pipeline (Propshaft + Tailwind standalone).

- `tailwind/application.css` — **the token seam**: the `:root` block owns the
  theme (`--app-primary` and friends); the kit styles against those names
  (`bg-(--app-primary)`). Retheming is editing this one block.
- `builds/tailwind.css` — the compiled output (`bin/rails tailwindcss:build`).
- `stylesheets/`, `images/` — served as-is by Propshaft.

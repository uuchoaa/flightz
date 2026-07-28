# app/entities — ring 1

The innermost ring: enterprise data and rules that depend on **nothing**
outward. No `Result`, no `Registry`, no controllers, no `Infer` — the
architecture test enforces this.

- `command.rb` — the ledger row: every write is a `Command` before it is
  anything else; carries `status`, `level`, `payload`, `result`, and a
  self-referential `parent_id` for step children.
- `setting.rb` — key/value app config (JSON scalars); defaults live with the
  use cases, this ring only persists.
- `application_record.rb` — the Active Record base.

Replaces `app/models` — a directory named `models` is a test failure here.

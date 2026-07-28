# app/jobs — ring 4 (delivery)

The async half of the W. A write is enqueued as a job; the job dispatches to
its use case and lands the value.

- `command_job.rb` — the DBWriter: dequeues a ledger row, dispatches to its
  registered handler, stores the `Result` on the row, and broadcasts the
  confirm on the `"commands"` channel. An unexpected raise is a bug, not a
  domain outcome — the job retries, the ledger stays the source of truth.

Backed by Solid Queue, run inside Puma (`SOLID_QUEUE_IN_PUMA=1`) — no separate
worker host.

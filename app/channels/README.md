# app/channels — ring 4 (delivery)

The websocket edge of the W. Command confirmations are broadcast here so a
client learns a write's outcome without polling (the HTTP response to a write
is only a 202 + command id).

- `commands_channel.rb` — clients subscribe to `"commands"`; `CommandJob`
  broadcasts each confirm.
- `application_cable/` — the Action Cable connection/channel base.

Backed by Solid Cable (SQLite), so this runs inside the single Puma process.

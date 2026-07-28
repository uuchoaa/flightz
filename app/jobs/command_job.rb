# The DBWriter: dequeues a ledger row, dispatches to its handler, lands the
# Result and broadcasts the confirm. An unexpected raise here is a bug, not a
# domain outcome — the job retries, the command stays pending, the ledger
# remains the source of truth.
class CommandJob < ApplicationJob
  queue_as :default

  def perform(command_id)
    command = Command.find(command_id)
    handler = Registry.command(command.name) or
      return land(command, Result.err(:unknown_command))

    payload = command.payload.symbolize_keys.merge(_command_id: command.id)
    land(command, handler.new.call(payload))
  end

  private

  # The ledger row stores exactly what the confirm carried, so the polling
  # fallback resolves to the same value the socket would have delivered.
  def land(command, result)
    confirm = result.as_json.symbolize_keys
    confirm[:notice] = notice_for(command, result) if result.ok?
    command.update!(status: result.ok? ? "done" : "failed", result: confirm)
    ActionCable.server.broadcast("commands", { command_id: command.id, **confirm })
  end

  def notice_for(command, result)
    result.notice || I18n.t("commands.#{command.name}.done", default: nil)
  end
end

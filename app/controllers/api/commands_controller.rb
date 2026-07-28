module Api
  # The entire write side: shape-check, ledger row, enqueue, 202. Real
  # validation happens in the domain, as values, and arrives on the socket.
  class CommandsController < ApplicationController
    def create
      handler = Registry.command(params[:name]) or return head(:not_found)
      payload = params.fetch(:payload, ActionController::Parameters.new)
                      .permit(*handler::PAYLOAD)
      command = Command.create!(name: params[:name], payload: payload.to_h)
      CommandJob.perform_later(command.id)
      render json: { command_id: command.id }, status: :accepted
    end

    # Polling fallback / page-reload recovery.
    def show
      command = Command.find_by(id: params[:id]) or return head(:not_found)
      render json: command.as_json(only: %i[id name status result])
    end
  end
end

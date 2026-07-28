class CommandsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "commands"
  end
end

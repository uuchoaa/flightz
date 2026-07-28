# frozen_string_literal: true

# A live console: when `auto` is set the `stream` Stimulus controller opens
# an EventSource to `url` (carrying `params` as the query string) on connect,
# appends one line per server step, and drops the final rendered fragment
# into the results slot. When not auto it just shows the `idle` hint and
# waits. Agnostic of what is being streamed.
class Components::Stream < Components::Base
  def initialize(url:, params: {}, auto: false, idle: nil)
    @url = url
    @params = params
    @auto = auto
    @idle = idle
  end

  def view_template
    div(data: { controller: "stream", stream_url_value: @url,
                stream_params_value: @params.to_json, stream_auto_value: @auto.to_s }) do
      div(class: "border border-gray-200 rounded-2xl p-4 my-6 font-mono text-sm bg-gray-50") do
        div(class: "flex flex-col gap-1", data: { stream_target: "log" }) do
          span(class: "text-gray-500") { @idle } if @idle && !@auto
        end
      end
      div(data: { stream_target: "results" })
    end
  end
end

# Server-Sent Events delivery for the search: runs the ring-2 query with a
# log callback that narrates each pipeline step to the browser, then streams
# the rendered offers as a final event. Isolated in its own controller so
# ActionController::Live governs only this action.
class FlightsStreamController < ApplicationController
  include ActionController::Live

  def show
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no" # let nginx flush each event

    criteria = params.permit(:origin, :destination, :departure_date, :return_date).to_h.symbolize_keys
    steps = []
    log = ->(key, **data) do
      steps << { key:, data: }
      emit("step", key:, text: step_text(key, data))
    end

    answer = Flights::Queries::Search.new.call(criteria, log:)
    record_search(criteria, answer, steps)
    result = wrap(answer)
    html = render_to_string(Views::FlightsResults.new(result:), layout: false)
    emit("done", html:, count: result[:offers]&.size || 0)
  rescue ActionController::Live::ClientDisconnected
    nil # the browser navigated away mid-stream
  ensure
    response.stream.close
  end

  private

  def emit(event, data)
    response.stream.write("event: #{event}\n")
    response.stream.write("data: #{data.to_json}\n\n")
  end

  def step_text(key, data)
    friendly = data.transform_values { |value| value.is_a?(Array) ? value.join(", ") : value }
    I18n.t("flights.step.#{key}", default: key.to_s.humanize, **friendly)
  end

  def wrap(answer)
    return answer if answer[:error]

    { offers: answer[:best_flights].map { |flight| FlightPresenter.new(flight) } }
  end

  # Every search lands a ledger row so the logs screen shows a real history:
  # an info summary with each pipeline step as a debug child. A read,
  # audited — not routed through the W. Never breaks the search.
  def record_search(criteria, answer, steps)
    status, result =
      if answer[:error]
        [ "failed", { "err" => { "code" => answer[:error].to_s } } ]
      else
        [ "done", { "ok" => { "count" => answer[:best_flights].size } } ]
      end
    parent = Command.create!(name: "search", level: "info", status:,
                             payload: criteria.transform_keys(&:to_s), result:)
    steps.each do |step|
      Command.create!(parent_id: parent.id, name: step[:key].to_s, level: "debug",
                      status: "done", payload: step[:data].transform_keys(&:to_s))
    end
  rescue ActiveRecord::ActiveRecordError
    nil
  end
end

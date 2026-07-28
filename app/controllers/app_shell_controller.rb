# The delivery: reads go straight to the ring-2 queries, get wrapped by
# presenters, and land in Phlex screens; writes stay on the W via
# /api/commands from the Stimulus controllers.
class AppShellController < ApplicationController
  layout "app_shell"

  # A first visit lands on a sensible round-trip so the screen shows offers
  # instead of an empty prompt; any submitted criteria take over.
  DEFAULT_ROUTE = { origin: "GRU", destination: "REC" }.freeze

  # The screen renders instantly with the criteria; the search runs over SSE
  # (flights_stream) only once the form is submitted, so a first visit just
  # lands on a pre-filled form.
  def index
    render Views::FlightsScreen.new(criteria: search_criteria, auto: search_submitted?)
  end

  def logs
    level = Views::LogsScreen::LEVELS.include?(params[:level]) ? params[:level] : "info"
    events = Ledger::Queries::Events.new.call(limit: 200, level:).map { |raw| EventPresenter.new(raw) }
    render Views::LogsScreen.new(events:, level:)
  end

  def settings
    render Views::SettingsScreen.new(settings: settings_values)
  end

  private

  def search_submitted?
    submitted_criteria.values_at(:origin, :destination, :departure_date, :return_date).all?(&:present?)
  end

  def submitted_criteria
    params.permit(:origin, :destination, :departure_date, :return_date).to_h.symbolize_keys
  end

  # The submitted criteria, or the default route with dates a month out so
  # the landing form is pre-filled with something sensible.
  def search_criteria
    given = submitted_criteria
    return given if given.values_at(:origin, :destination, :departure_date, :return_date).all?(&:present?)

    DEFAULT_ROUTE.merge(
      departure_date: Date.current.next_month.strftime("%Y-%m-%d"),
      return_date: (Date.current.next_month + 10).strftime("%Y-%m-%d")
    )
  end

  def settings_values
    Settings::Queries::Settings.new.call({})[:values]
  end
end

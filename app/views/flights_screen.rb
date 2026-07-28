# frozen_string_literal: true

# The search screen: a URL-driven GET form and a live console that streams
# the search steps and injects the offers when they land.
class Views::FlightsScreen < Views::Base
  stimulus :command, :stream

  def initialize(criteria:, auto: false)
    @criteria = criteria
    @auto = auto
  end

  def view_template
    shell(active: :flights) do
      Stack(gap: 0) do
        PageHeading(t("flights.title"), subtitle: t("flights.subtitle"))
        criteria_form
        Stream(url: flights_stream_path, params: @criteria, auto: @auto, idle: t("flights.prompt"))
      end
    end
  end

  private

  def criteria_form
    Card do
      QueryForm(root_path, values: @criteria) do |f|
        f.field :origin, t("flights.origin"), placeholder: "CGH", required: true, width: :narrow
        f.field :destination, t("flights.destination"), placeholder: "JPA", required: true, width: :narrow
        f.field :departure_date, t("flights.departure"), type: :date, required: true
        f.field :return_date, t("flights.return"), type: :date, required: true
        f.submit t("flights.search")
      end
    end
  end
end

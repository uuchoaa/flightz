# frozen_string_literal: true

class Views::LogsScreen < Views::Base
  LEVELS = %w[all info debug].freeze

  def initialize(events:, level: "info")
    @events = events
    @level = level
  end

  def view_template
    shell(active: :logs) do
      PageHeading(t("logs.title"), subtitle: t("logs.subtitle"))
      level_filter

      Table(rows: @events, empty: t("logs.empty")) do |tbl|
        tbl.col t("logs.col.id"), :id, muted: true
        tbl.col(t("logs.col.level")) { |e| e.level }
        tbl.col(t("logs.col.command")) { |e| command_cell(e) }
        tbl.col t("logs.col.status"), :status
        tbl.col(t("logs.col.payload"), truncate: true) { |e| payload_cell(e) }
        tbl.col t("logs.col.at"), :at, muted: true
      end
    end
  end

  private

  def level_filter
    Tabs(active: @level, options: LEVELS.map do |level|
      [ level, t("logs.level.#{level}"), app_logs_path(level:) ]
    end)
  end

  def command_cell(event)
    Row(gap: 2) do
      IconHint(:indent, size: 14) if event.child?
      Text(event.name, weight: :semibold, size: :sm)
    end
  end

  def payload_cell(event)
    Stack(gap: 0) do
      Text(event.payload_summary, size: :sm, tone: :muted, truncate: true)
      Text(event.error_code, size: :xs, tone: :danger) if event.error_code
    end
  end
end

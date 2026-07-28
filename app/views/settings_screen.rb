# frozen_string_literal: true

class Views::SettingsScreen < Views::Base
  def initialize(settings:)
    @settings = settings
  end

  def view_template
    shell(active: :settings) do
      Stack(gap: 0, narrow: true) do
        PageHeading(t("settings.title"), subtitle: t("settings.subtitle"))
        preferences
      end
    end
  end

  private

  def preferences
    Card(t("settings.preferences")) do
      Form("update_settings", done: t("settings.saved"), values: @settings) do |f|
        f.field :locale, t("settings.locale"), options: Settings::Defaults::LOCALES
        f.submit t("settings.save")
      end
    end
  end
end

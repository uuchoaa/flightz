# frozen_string_literal: true

class Views::Base < Components::Base
  include Components::Labels

  # Declares which Stimulus controllers the shell wrapper carries, so
  # actions anywhere inside the screen (rows, chips, menus) can reach them.
  #   stimulus :command, :search, :drawer
  def self.stimulus(*names)
    @stimulus = names.map(&:to_s)
  end

  def self.stimulus_controllers
    @stimulus || [ "command" ]
  end

  private

  def shell(active:, aside: nil, &)
    Shell(nav: nav_entries, active:, controllers: self.class.stimulus_controllers, aside:, &)
  end

  def nav_entries
    [
      Components::TopNav::Entry.new(key: :flights, label: t("nav.flights"), icon: :plane, href: root_path),
      Components::TopNav::Entry.new(key: :logs, label: t("nav.logs"), icon: :receipt, href: app_logs_path),
      Components::TopNav::Entry.new(key: :settings, label: t("nav.settings"), icon: :tune, href: app_settings_path)
    ]
  end
end

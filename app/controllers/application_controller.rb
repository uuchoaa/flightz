class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # The household speaks one language: the locale is a setting, not a
  # header. Applies to the screens and to command notices alike.
  around_action :with_household_locale

  private

  def with_household_locale(&)
    I18n.with_locale(Settings::Defaults.current["locale"], &)
  end
end

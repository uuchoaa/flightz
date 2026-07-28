require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # Every confirm rides the polling fallback here (silent test cable), so
  # UI reactions take a couple of seconds by design.
  Capybara.default_max_wait_time = 8
end

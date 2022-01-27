require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  include ActionView::Helpers::TranslationHelper
end

Capybara.configure do |config|
  config.default_normalize_ws = true
end

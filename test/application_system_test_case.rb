require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end

Capybara.configure do |config|
  config.default_normalize_ws = true
end

Capybara.modify_selector :alert do
  xpath do |name, **|
    XPath.descendant[
      XPath.descendant[XPath.attr(:role) == "alert"] |
      XPath.descendant[:output]
    ][XPath.string.n.is(name.to_s)]
  end
end

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end

Capybara.configure do |config|
  config.default_normalize_ws = true
end

Capybara.add_selector :cell do
  xpath do |locator|
    td = XPath.descendant(:td)

    locator.nil? ? td : td[XPath.n.string.is(locator)]
  end

  node_filter :column do |td, column|
    table = td.find :xpath, "./ancestor::table"
    row = td.find :xpath, "./ancestor::tr"
    index = row.all("td").map(&:path).index(td.path)

    table.has_selector?("th:nth-child(#{index + 1})", text: column) ||
      row.has_selector?("th[scope=row]", text: column)
  end
end

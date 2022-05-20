Rails.application.configure do
  if ENV.key?("REPL_SLUG")
    ENV["DATABASE_URL"] = "sqlite3://#{Rails.root.join("db/#{Rails.env}.sqlite3")}"

    config.action_controller.allow_forgery_protection = false

    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "ALLOWFROM replit.com"
    }
    config.hosts << /.*\.repl.co/
  end
end

Rails.application.configure do
  if ENV["REPLIT"]
    config.action_controller.allow_forgery_protection = false

    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "ALLOWFROM replit.com"
    }
    config.hosts << /.*\.repl.co/
  end
end

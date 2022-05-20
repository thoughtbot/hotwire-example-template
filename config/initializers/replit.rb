Rails.application.configure do
  repl_slug, repl_owner = ENV.values_at("REPL_SLUG", "REPL_OWNER")

  if repl_slug.present? && repl_owner.present?
    config.action_controller.allow_forgery_protection = false
    config.action_controller.default_url_options = { host: "#{repl_slug}.#{repl_owner}.repl.co" }
    config.active_storage.default_url_options = config.action_controller.default_url_options
    config.action_mailer.default_url_options = config.action_controller.default_url_options

    config.session_store :cookie_store, same_site: :none, secure: true

    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "ALLOWFROM replit.com",
      "Access-Control-Allow-Origin" => "repl.co",
    }

    config.hosts << /.*\.repl.co/

    config.after_initialize do
      ActionCable.server.config.cable[:adapter] = "async"
    end

    ENV["DATABASE_URL"] = "sqlite3://#{Rails.root.join("db/#{Rails.env}.sqlite3")}"
  end
end

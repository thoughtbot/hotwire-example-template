// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "tailwind.config"
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"

addEventListener("turbo:submit-end", ({ target, detail: { fetchResponse } }) => {
  if (fetchResponse.redirected && fetchResponse.header("Turbo-Frame") == "_top") {
    Turbo.visit(fetchResponse.location)
  }
})

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "tailwind.config"
import "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"

addEventListener("turbo:submit-start", (submitStart) => {
  const { formElement, submitter } = submitStart.detail.formSubmission

  if (submitter) submitter.disabled = true

  formElement.addEventListener("turbo:submit-end", (submitEnd) => {
    const { formElement, submitter } = submitEnd.detail.formSubmission

    if (submitter) submitter.disabled = false
  }, { once: true })
})

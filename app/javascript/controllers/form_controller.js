import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  hideValidationMessage(event) {
    event.stopPropagation()
    event.preventDefault()
  }
}

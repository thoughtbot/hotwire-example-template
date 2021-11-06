import { Controller } from "@hotwired/stimulus"
import "https://cdn.skypack.dev/form-request-submit-polyfill"

export default class extends Controller {
  requestSubmit(event) {
    const { target, key, ctrlKey, metaKey, params } = event
    const modified = ctrlKey || metaKey

    if (params.key == key && params.modified == modified) {
      event.preventDefault()

      this.element.requestSubmit()
    }
  }
}

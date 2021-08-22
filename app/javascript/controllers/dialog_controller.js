import { Controller } from "@hotwired/stimulus"
import dialogPolyfill from "https://cdn.skypack.dev/dialog-polyfill"

export default class extends Controller {
  initialize() {
    dialogPolyfill.registerDialog(this.element)
  }

  showModal() {
    if (this.element.open) return
    else this.element.showModal()
  }
}

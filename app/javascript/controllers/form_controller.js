import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "preview" ] }

  connect() {
    this.previewTarget.hidden = true
  }

  preview() {
    this.previewTarget.click()
  }
}

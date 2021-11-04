import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "element" ] }

  push() {
    const { activeElement } = document

    if (activeElement) {
      this.activeElementId = activeElement.id
    }
  }

  elementTargetConnected(target) {
    if (this.activeElementId && target.id == this.activeElementId) {
      target.focus()
    }
  }
}

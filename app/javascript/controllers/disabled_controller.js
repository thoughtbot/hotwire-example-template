import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "input" ] }

  toggle({ target: { checked } }) {
    for (const input of this.inputTargets) {
      input.disabled = !checked
    }
  }
}

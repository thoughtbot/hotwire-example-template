import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "anchor" ]

  encode({ target: { name, value } }) {
    for (const anchor of this.anchorTargets) {
      anchor.search = new URLSearchParams({ [name]: value })
    }
  }
}

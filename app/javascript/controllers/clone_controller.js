import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "template" ]

  append() {
    for (const { content } of this.templateTargets) {
      this.element.append(content.cloneNode(true))
    }
  }
}

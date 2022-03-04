import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source" ]

  append(event) {
    const destination = event.target

    for (const { content } of this.sourceTargets) {
      destination.append(content.cloneNode(true))
    }
  }
}

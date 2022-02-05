import { TemplateInstance } from "https://cdn.skypack.dev/@github/template-parts"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "template" ]
  static values = { index: Number, key: String }

  templateTargetConnected(target) {
    const templateInstance = new TemplateInstance(target, {
      [this.keyValue]: this.indexValue
    })

    target.content.replaceChildren(templateInstance)

    this.indexValue++
  }
}

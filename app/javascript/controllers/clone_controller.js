import { Controller } from "@hotwired/stimulus"
import { TemplateInstance } from "https://cdn.skypack.dev/@github/template-parts"

export default class extends Controller {
  static get targets() { return [ "output", "template" ] }
  static get values() { return { placeholder: String, selector: String } }

  append({ target }) {
    for (const file of target.files) {
      const id = (new Date()).getTime()
      const clonedTemplate = new TemplateInstance(this.templateTarget, { [this.placeholderValue]: id })

      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)

      const input = clonedTemplate.querySelector(this.selectorValue)
      input.files = dataTransfer.files

      this.outputTarget.append(clonedTemplate)
    }

    target.value = null
  }
}

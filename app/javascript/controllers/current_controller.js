import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get classes() { return [ "user" ] }
  static get values() { return { token: String } }

  tokenValueChanged(value) {
    const isCurrent = value && value == this.tokenFromMeta

    for (const className of this.userClasses) {
      this.element.classList.toggle(className, isCurrent)
    }
  }

  get tokenFromMeta() {
    const [ meta ] = document.getElementsByName(this.identifier)

    return meta?.content
  }
}

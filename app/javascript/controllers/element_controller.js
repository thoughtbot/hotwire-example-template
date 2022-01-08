import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "click" ] }

  click() {
    this.clickTargets.forEach(target => target.click())
  }
}

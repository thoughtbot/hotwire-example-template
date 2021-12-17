import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  cache() {
    this.element.setAttribute("data-turbo-permanent", "")
  }

  invalidate() {
    this.element.removeAttribute("data-turbo-permanent")
  }
}

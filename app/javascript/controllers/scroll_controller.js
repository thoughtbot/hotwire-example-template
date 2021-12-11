import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { top: Number }

  cache() {
    this.topValue = this.element.scrollTop
  }

  read() {
    this.element.scrollTop = this.topValue
  }

  invalidate({ detail: { url } }) {
    const { pathname } = new URL(url)

    if (window.location.pathname != pathname) this.topValue = 0
  }

  preventVisitScroll() {
    const { currentVisit } = Turbo.session.navigator

    if (currentVisit) currentVisit.scrolled = true
  }
}

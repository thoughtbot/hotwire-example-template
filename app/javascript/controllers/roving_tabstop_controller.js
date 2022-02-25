import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "focusable" ]

  focusableTargetConnected(target) {
    const [ firstElement ] = this.focusableTargets

    if (target.hasAttribute("tabindex")) return
    else if (target == firstElement) target.setAttribute("tabindex", 0)
    else target.setAttribute("tabindex", -1)
  }
}

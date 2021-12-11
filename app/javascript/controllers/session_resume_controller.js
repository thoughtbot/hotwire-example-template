import { Controller } from "@hotwired/stimulus"
import { setForm, persistResumableFields, restoreResumableFields } from "https://cdn.skypack.dev/@github/session-resume"

export default class extends Controller {
  static targets = [ "field" ]

  setForm(event) {
    setForm(event)
  }

  cache() {
    const selector = `[data-${this.identifier}-target="field"]`

    persistResumableFields(getPageID(), { selector })
  }

  fieldTargetConnected() {
    restoreResumableFields(getPageID())
  }
}

function getPageID() {
  return window.location.pathname
}

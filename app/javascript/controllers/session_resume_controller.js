import { Controller } from "@hotwired/stimulus"
import { setForm, persistResumableFields, restoreResumableFields } from "https://cdn.skypack.dev/@github/session-resume"

export default class extends Controller {
  static values = { selector: String }

  setForm(event) {
    setForm(event)
  }

  cache() {
    persistResumableFields(getPageID(), { selector: this.selectorValue })
  }

  read() {
    restoreResumableFields(getPageID())
  }
}

function getPageID() {
  return window.location.pathname
}

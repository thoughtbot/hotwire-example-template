import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "column" ]
  static values = { directions: Object, column: Number, row: Number }

  columnTargetConnected(target) {
    if (target.hasAttribute("tabindex")) return

    const index = this.columnTargets.indexOf(target)
    const tabindex = index == 0 ?
       0 :
      -1

    target.setAttribute("tabindex", tabindex)
  }

  columnValueChanged(value) {
    this.columnTargets.forEach((column, index) => {
      const tabindex = index == value ?
         0 :
        -1

      column.setAttribute("tabindex", tabindex)
    })
  }

  captureColumn({ target }) {
    this.columnValue = this.columnTargets.indexOf(target) || 0
  }

  moveColumn({ key }) {
    if (key in this.directionsValue) {
      const index = this.columnValue + this.directionsValue[key]

      this.columnTargets[index]?.focus()
    }
  }
}

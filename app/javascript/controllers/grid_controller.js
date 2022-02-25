import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "column" ]

  columnTargetConnected(target) {
    if (target.hasAttribute("tabindex")) return

    const index = this.columnTargets.indexOf(target)
    const tabindex = index == 0 ?
       0 :
      -1

    target.setAttribute("tabindex", tabindex)
  }

  captureColumn({ target }) {
    for (const column of this.columnTargets) {
      const tabindex = column == target ?
         0 :
        -1

      column.setAttribute("tabindex", tabindex)
    }
  }

  moveColumn({ key, params: { directions } }) {
    if (key in directions) {
      const index = this.columnTargets.findIndex(target => target.tabIndex > -1)
      const column = this.columnTargets[index + directions[key]]

      if (column) column.focus()
    }
  }
}

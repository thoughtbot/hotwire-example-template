import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  enable({ target }) {
    const elements = Array.from(this.element.elements)
    const selectedElements = "selectedOptions" in target ?
      target.selectedOptions :
      [ target ]

    for (const element of elements.filter(element => element.name == target.name)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = true
    }

    for (const element of controlledElements(...selectedElements)) {
      if (element instanceof HTMLFieldSetElement) element.disabled = false
    }
  }
}

function controlledElements(...selectedElements) {
  return selectedElements.flatMap(selectedElement =>
    getElementsByTokens(selectedElement.getAttribute("aria-controls"))
  )
}

function getElementsByTokens(tokens) {
  const ids = (tokens ?? "").split(/\s+/)

  return ids.map(id => document.getElementById(id))
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get classes() { return [ "accepting" ] }
  static get targets() { return [ "drop", "template" ] }

  start({ dataTransfer, target }) {
    const template = this.templateTargets.find(template => target.contains(template))
    const image = target.cloneNode(true)

    dataTransfer.setData("text/html", template?.innerHTML)
  }

  accept(event) {
    const { currentTarget, dataTransfer } = event

    event.preventDefault()

    dataTransfer.dropEffect = currentTarget.getAttribute("aria-dropeffect")
    currentTarget.classList.add(...this.acceptingClasses)
  }

  reject({ currentTarget }) {
    currentTarget.classList.remove(...this.acceptingClasses)
  }

  insert(event) {
    const { currentTarget, dataTransfer } = event

    event.preventDefault()

    const dropTarget = this.dropTargets.find(dropTarget => currentTarget.contains(dropTarget))

    dropTarget?.insertAdjacentHTML("beforeend", dataTransfer.getData("text/html"))
  }
}

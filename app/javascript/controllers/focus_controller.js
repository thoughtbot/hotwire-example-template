import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "item" ] }

  initialize() {
    this.lastActiveElement = null
    this.lastClickedElement = null
  }

  itemTargetConnected(target) {
    const { id, href } = this.lastActiveElement || {}

    if (hasMatchingId(id, target) && canFocus(target)) {
      if (href == window.location.href) {
        target.focus()
      } else {
        this.lastActiveElement = null
        this.lastClickedElement = null
      }
    }
  }

  itemTargetDisconnected(target) {
    if (target == document.activeElement) {
      this.lastActiveElement = { id: target.id, href: window.location.href }
    } else if (document.body == document.activeElement && hasMatchingId(target.id, this.lastClickedElement)) {
      this.lastActiveElement = this.lastClickedElement
      this.lastClickedElement = null
    }
  }

  push({ target }) {
    if (document.activeElement == document.body) return

    const item = this.itemTargets.find(item => item.contains(target))

    this.lastClickedElement = item ?
      { id: item.id, href: window.location.href } :
      null
  }
}

function hasMatchingId(id, element) {
  return id && id == element?.id
}

function canFocus(element) {
  if (element.hidden || getComputedStyle(element) == "none") {
    return false
  } else {
    return true
  }
}

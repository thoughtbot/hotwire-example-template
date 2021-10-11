import { Controller } from "@hotwired/stimulus"

const idsToScrollTops = {}

export default class extends Controller {
  static get targets() { return [ "container" ] }

  containerTargetConnected(target) {
    const scrollTop = idsToScrollTops[target.id]

    if (scrollTop) target.scroll(0, scrollTop)
  }

  track({ target }) {
    if (target.id) idsToScrollTops[target.id] = target.scrollTop
  }
}

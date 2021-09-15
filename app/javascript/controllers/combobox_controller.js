import { Controller } from "@hotwired/stimulus"
import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"

export default class extends Controller {
  static get targets() { return [ "input", "list" ] }

  disconnect() {
    this.combobox?.destroy()
  }

  listTargetConnected() {
    this.start()
  }

  start() {
    this.combobox?.destroy()

    this.combobox = new Combobox(this.inputTarget, this.listTarget)
    this.combobox.start()
  }

  stop() {
    this.combobox?.stop()
  }
}

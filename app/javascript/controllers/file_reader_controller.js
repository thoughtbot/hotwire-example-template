import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "input", "label", "image" ] }

  inputTargetConnected({ files: [ file ] }) {
    const fileReader = new FileReader()

    if (file) {
      for (const label of this.labelTargets) {
        label.innerHTML = file.name
      }
      this.imageTarget.alt = file.name

      fileReader.addEventListener("load", ({ target }) => this.imageTarget.src = target.result)
      fileReader.readAsDataURL(file)
    }
  }
}

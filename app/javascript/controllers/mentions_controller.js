import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "editor" ] }

  insert({ target: { value, innerHTML } }) {
    const { editor } = this.editorTarget

    editor.insertAttachment(new Trix.Attachment({ sgid: value, content: innerHTML }))
  }
}

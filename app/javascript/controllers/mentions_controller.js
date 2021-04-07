import { Controller } from "@hotwired/stimulus"
import Combobox from "https://cdn.skypack.dev/@github/combobox-nav"

export default class extends Controller {
  static get targets() { return [ "editor", "listbox", "submit" ] }
  static get values() { return { wordPattern: String, breakPattern: String } }

  disconnect() {
    this.toggle(false)
  }

  // Actions

  insert({ target: { value, innerHTML } }) {
    const { editor } = this.editorTarget
    const selectedRange = findWordBoundsFromCursor(editor, this.breakPatternValue)

    editor.setSelectedRange(selectedRange)
    editor.deleteInDirection("backward")
    editor.insertAttachment(new Trix.Attachment({ sgid: value, content: innerHTML }))
  }

  expand({ target: { editor } }) {
    const mention = findMentionFromCursor(editor, this.wordPatternValue, this.breakPatternValue)

    if (mention) {
      const { bottom, left } = editor.getClientRectAtPosition(editor.getPosition())
      this.listboxTarget.style.top = bottom + "px"
      this.listboxTarget.style.left = left + "px"

      this.toggle(true)
      this.submitTarget.value = mention
      this.submitTarget.click()
    } else {
      this.toggle(false)
    }
  }

  collapseOnEscape({ key }) {
    if (key == "Escape") this.collapse()
  }

  collapseOnCursorExit({ target: { editor } }) {
    const mention = findMentionFromCursor(editor, this.wordPatternValue, this.breakPatternValue)

    if (mention) return
    else this.toggle(false)
  }

  collapse() {
    if (this.editorTarget.hasAttribute("aria-activedescendant")) return
    else this.toggle(false)
  }

  // Private

  toggle(expanded) {
    if (expanded) {
      this.listboxTarget.hidden = false
      this.listboxTarget.setAttribute("role", "listbox")
      this.editorTarget.setAttribute("role", "combobox")
      this.editorTarget.setAttribute("autocomplete", "username")
      this.editorTarget.setAttribute("autocorrect", "off")

      this.combobox?.destroy()
      this.combobox = new Combobox(this.editorTarget, this.listboxTarget)
      this.combobox.start()
    } else {
      this.listboxTarget.hidden = true
      this.listboxTarget.removeAttribute("role")
      this.editorTarget.setAttribute("role", "textbox")
      this.editorTarget.removeAttribute("autocomplete")
      this.editorTarget.removeAttribute("autocorrect")

      this.combobox?.destroy()
    }
  }
}

function findMentionFromCursor(editor, wordPattern, breakPattern) {
  const [ start, end ] = findWordBoundsFromCursor(editor, breakPattern)
  const word = editor.getDocument().toString().slice(start, end)
  const [ mention ] = word.match(new RegExp(wordPattern)) || []

  return mention
}

function findWordBoundsFromCursor(editor, breakPattern) {
  const content = editor.getDocument().toString()
  const position = editor.getPosition()
  breakPattern = new RegExp(breakPattern)

  return findWordBoundsFromStringAtPosition(content, position, (char) => breakPattern.test(char))
}

function findWordBoundsFromStringAtPosition(string, position, characterMatchesWordBoundary) {
  let start = position
  let index = position
  while(--index >= 0) {
    const char = string.charAt(index)
    if (characterMatchesWordBoundary(char)) break
    start = index
  }

  let end = position
    index = position
  while(index < string.length) {
    const char = string.charAt(index)
    if (characterMatchesWordBoundary(char)) break
    end = ++index
  }

  if (start != end) {
    return [ start, end ]
  } else {
    return [ -1, -1 ]
  }
}

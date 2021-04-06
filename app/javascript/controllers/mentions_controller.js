import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() { return [ "editor", "listbox", "submit" ] }
  static get values() { return { wordPattern: String, breakPattern: String } }

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
      this.toggle(true)
      this.submitTarget.value = mention
      this.submitTarget.click()
    } else {
      this.toggle(false)
    }
  }

  // Private

  toggle(expanded) {
    if (expanded) {
      this.listboxTarget.hidden = false
      this.editorTarget.setAttribute("autocomplete", "username")
      this.editorTarget.setAttribute("autocorrect", "off")
    } else {
      this.listboxTarget.hidden = true
      this.editorTarget.removeAttribute("autocomplete")
      this.editorTarget.removeAttribute("autocorrect")
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

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  mergeWithSearchParams({ formData, target }) {
    const keys = Array.from(formData.keys())
    const action = new URL(target.action, document.baseURI)

    for (const [ key, value ] of action.searchParams) {
      if (keys.includes(key)) continue

      formData.append(key, value)
    }
  }
}

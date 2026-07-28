import { Controller } from "@hotwired/stimulus"
import { refreshPage, runAndToast } from "lib/commands"

// A form whose submit is one command: the fields become the payload.
export default class extends Controller {
  static values = { name: String, done: String }

  async submit(event) {
    event.preventDefault()
    const payload = Object.fromEntries(new FormData(event.target))
    const result = await runAndToast(this.nameValue, payload, { doneText: this.doneValue })
    if (!result.err) {
      event.target.reset?.()
      await refreshPage()
    }
  }
}

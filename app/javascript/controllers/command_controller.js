import { Controller } from "@hotwired/stimulus"
import { refreshPage, runAndToast } from "lib/commands"

// Generic single-command trigger: the element carries the command name,
// payload and toast text as data attributes. Confirms, runs, refreshes.
export default class extends Controller {
  async run(event) {
    const el = event.currentTarget
    if (el.dataset.confirm && !window.confirm(el.dataset.confirm)) return
    await this.dispatchCommand(el, JSON.parse(el.dataset.payload ?? "{}"))
  }

  // Same, but one payload field comes from a prompt (e.g. a rename).
  async promptRun(event) {
    const el = event.currentTarget
    const value = window.prompt(el.dataset.promptLabel, el.dataset.promptDefault ?? "")
    if (!value?.trim()) return
    const payload = { ...JSON.parse(el.dataset.payload ?? "{}"), [el.dataset.promptKey]: value.trim() }
    await this.dispatchCommand(el, payload)
  }

  async dispatchCommand(el, payload) {
    el.closest("details")?.removeAttribute("open")
    const result = await runAndToast(el.dataset.name, payload, { doneText: el.dataset.done })
    if (!result.err) await refreshPage()
  }
}

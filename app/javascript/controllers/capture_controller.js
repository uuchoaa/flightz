import { Controller } from "@hotwired/stimulus"
import { refreshPage, runAndToast, t } from "lib/commands"

// The capture bar: one utterance -> the capture command -> confirm toast.
export default class extends Controller {
  static targets = ["input", "button"]
  static values = { timeout: { type: Number, default: 60 } }

  connect() {
    this.idleLabel = this.buttonTarget.textContent
  }

  async submit(event) {
    event.preventDefault()
    const utterance = this.inputTarget.value.trim()
    if (!utterance || this.busy) return

    this.toggle(true)
    const result = await runAndToast("capture", { utterance }, {
      doneText: t("registered", { text: utterance }),
      timeoutMs: this.timeoutValue * 1000,
    })
    this.toggle(false)
    if (!result.err) {
      this.inputTarget.value = ""
      await refreshPage()
    }
  }

  toggle(busy) {
    this.busy = busy
    this.inputTarget.disabled = busy
    this.buttonTarget.disabled = busy
    this.buttonTarget.textContent = busy ? t("sending") : this.idleLabel
  }
}

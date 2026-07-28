import { Controller } from "@hotwired/stimulus"

// Material-style snackbar: listens for app:toast events from lib/commands.
export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.listener = (event) => this.show(event.detail)
    window.addEventListener("app:toast", this.listener)
  }

  disconnect() {
    window.removeEventListener("app:toast", this.listener)
  }

  show({ kind, text }) {
    clearTimeout(this.timer)
    this.messageTarget.textContent = text
    this.element.dataset.kind = kind
    this.element.classList.remove("hidden")
    this.timer = setTimeout(() => this.element.classList.add("hidden"), 4000)
  }
}

import { Controller } from "@hotwired/stimulus"
import { t } from "lib/commands"

// Client-side quick filter over the already-rendered rows; the counter
// shows "visible of total".
export default class extends Controller {
  static targets = ["input", "count", "row"]

  connect() {
    this.update()
  }

  update() {
    const term = (this.hasInputTarget ? this.inputTarget.value : "").trim().toLowerCase()
    let visible = 0
    this.rowTargets.forEach((row) => {
      const match = !term || (row.dataset.searchText ?? "").includes(term)
      row.classList.toggle("hidden", !match)
      if (match) visible += 1
    })
    if (this.hasCountTarget) this.countTarget.textContent = `${visible} ${t("of")} ${this.rowTargets.length}`
  }
}

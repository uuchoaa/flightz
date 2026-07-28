import { Controller } from "@hotwired/stimulus"

// Opens an SSE stream on connect, renders one line per "step" event with a
// running/done indicator, and injects the final "done" fragment. Generic:
// it knows nothing about what is being searched.
export default class extends Controller {
  static targets = ["log", "results"]
  static values = { url: String, params: Object, auto: Boolean }

  connect() {
    if (this.autoValue) this.start()
  }

  disconnect() {
    this.source?.close()
  }

  start() {
    this.logTarget.innerHTML = ""
    this.resultsTarget.innerHTML = ""
    const query = new URLSearchParams(this.paramsValue).toString()
    this.source = new EventSource(`${this.urlValue}?${query}`)
    this.source.addEventListener("step", (event) => this.appendStep(JSON.parse(event.data)))
    this.source.addEventListener("done", (event) => this.finish(JSON.parse(event.data)))
    this.source.onerror = () => this.settle()
  }

  appendStep(step) {
    this.settleLast()
    const line = document.createElement("div")
    line.dataset.state = "running"
    line.className = "flex items-center gap-2"
    const dot = document.createElement("span")
    dot.className = "inline-block w-2 h-2 rounded-full bg-amber-500 animate-pulse"
    const text = document.createElement("span")
    text.className = "text-gray-700"
    text.textContent = step.text
    line.append(dot, text)
    this.logTarget.appendChild(line)
  }

  finish(payload) {
    this.settleLast()
    this.resultsTarget.innerHTML = payload.html
    this.source?.close()
  }

  // The most recent running line is now complete: green, steady.
  settleLast() {
    const last = this.logTarget.lastElementChild
    if (!last || last.dataset.state === "done") return
    last.dataset.state = "done"
    const dot = last.firstElementChild
    if (dot) dot.className = "inline-block w-2 h-2 rounded-full bg-green-600"
  }

  settle() {
    this.settleLast()
    this.source?.close()
  }
}

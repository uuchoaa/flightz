import { html } from "lib/html"
import { Toaster } from "components/toaster"

export function App() {
  return html`
    <div>
      <${Toaster} />
    </div>
  `
}

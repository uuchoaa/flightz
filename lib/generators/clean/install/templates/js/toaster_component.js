// Composed from Catalyst's tokens — the kit ships no toast of its own.
import { useSyncExternalStore } from "react"
import { html } from "lib/html"
import { subscribe, snapshot, dismiss } from "lib/toaster"

const KIND_CLASSES = {
  ok: "bg-zinc-900 text-white dark:bg-white dark:text-zinc-900",
  err: "bg-red-600 text-white",
}

export function Toaster() {
  const toasts = useSyncExternalStore(subscribe, snapshot)
  return html`
    <div role="status" aria-live="polite"
         class="pointer-events-none fixed bottom-4 right-4 z-50 flex w-80 flex-col gap-2">
      ${toasts.map(
        (t) => html`
          <button key=${t.id} onClick=${() => dismiss(t.id)}
                  class="pointer-events-auto rounded-lg px-4 py-3 text-left text-sm/6 font-medium shadow-lg ${KIND_CLASSES[t.kind]}">
            ${t.message}
          </button>
        `
      )}
    </div>
  `
}

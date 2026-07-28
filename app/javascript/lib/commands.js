// The W from the client side: POST /api/commands -> poll the ledger row
// until it leaves "pending". Errors are values; outcomes surface as toasts.

const csrf = () => document.querySelector('meta[name="csrf-token"]')?.content ?? ""

export async function runCommand(name, payload, { timeoutMs = 15000 } = {}) {
  const response = await fetch("/api/commands", {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf() },
    body: JSON.stringify({ name, payload }),
  })
  const { command_id: id } = await response.json()

  const deadline = Date.now() + timeoutMs
  while (Date.now() < deadline) {
    const state = await (await fetch(`/api/commands/${id}`)).json()
    if (state.status !== "pending") return state.result ?? {}
    await new Promise((resolve) => setTimeout(resolve, 300))
  }
  return { err: { code: "timeout" } }
}

export function toast(kind, text) {
  window.dispatchEvent(new CustomEvent("app:toast", { detail: { kind, text } }))
}

// The layout injects window.I18N (the locale file's `js` block); keys
// interpolate %{name}-style placeholders.
export function t(key, vars = {}) {
  let text = (window.I18N ?? {})[key] ?? key
  for (const [name, value] of Object.entries(vars)) text = text.replace(`%{${name}}`, value)
  return text
}

export function describeError(err) {
  const details = Object.entries(err?.details ?? {})
    .map(([field, messages]) => `${field}: ${[].concat(messages).join("; ")}`)
    .join(" — ")
  return `${err?.code ?? t("error")}${details ? ` — ${details}` : ""}`
}

// Run one command and toast the outcome. Returns the result.
export async function runAndToast(name, payload, { doneText, timeoutMs } = {}) {
  const result = await runCommand(name, payload, { timeoutMs })
  if (result.err) toast("err", describeError(result.err))
  else toast("ok", doneText ?? t("done"))
  return result
}

// Re-render the current page server-side and swap the content region in
// place; Stimulus reconnects controllers inside the replaced subtree.
export async function refreshPage() {
  const html = await (await fetch(window.location.href)).text()
  const next = new DOMParser().parseFromString(html, "text/html").getElementById("page")
  const current = document.getElementById("page")
  if (next && current) current.replaceWith(next)
}

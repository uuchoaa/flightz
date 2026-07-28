// Flash dissolved into the confirm: a module-level toast store.
// Successes auto-dismiss; errors stick until dismissed.
let toasts = []
let nextId = 1
const listeners = new Set()

export function toast(kind, message, { sticky = kind === "err" } = {}) {
  if (!message) return
  const t = { id: nextId++, kind, message, sticky }
  toasts = [...toasts, t]
  emit()
  if (!sticky) setTimeout(() => dismiss(t.id), 4000)
}

export function dismiss(id) {
  toasts = toasts.filter((t) => t.id !== id)
  emit()
}

export function subscribe(fn) {
  listeners.add(fn)
  return () => listeners.delete(fn)
}

export const snapshot = () => toasts

const emit = () => listeners.forEach((fn) => fn(toasts))

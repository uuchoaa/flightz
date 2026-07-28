// The railway on the client: command() and query() never throw — they
// resolve to the same result values the domain produced.
// { ok: ..., notice } | { err: { code, details } }
import { cable } from "lib/cable"
import { toast } from "lib/toaster"

const csrf = () => document.querySelector('meta[name="csrf-token"]')?.content

const pending = new Map() // command_id -> resolve
const settled = new Set() // resolved via the ledger; skip late-confirm toasts
const listeners = new Set()

export function connectCommands() {
  cable.subscriptions.create("CommandsChannel", {
    received(data) {
      const resolve = pending.get(data.command_id)
      if (resolve) {
        pending.delete(data.command_id)
        resolve(data)
      } else if (!settled.has(data.command_id)) {
        // Late confirm: the caller gave up waiting — announce it now.
        toast(data.err ? "err" : "ok", data.notice || (data.err && `Failed: ${data.err.code}`))
      }
      listeners.forEach((fn) => fn(data))
    },
  })
}

// Every confirm, resolved or not — lists re-render on this.
export function onConfirm(fn) {
  listeners.add(fn)
  return () => listeners.delete(fn)
}

export async function command(name, payload = {}, { timeout } = {}) {
  const limit = timeout ?? window.COMMANDS_TIMEOUT ?? 20000
  let response
  try {
    response = await fetch("/api/commands", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf() },
      body: JSON.stringify({ name, payload }),
    })
  } catch {
    return { err: { code: "transport" } }
  }
  if (response.status !== 202) return { err: { code: "transport", status: response.status } }

  const { command_id } = await response.json()
  const confirm = await Promise.race([
    new Promise((resolve) => pending.set(command_id, resolve)),
    new Promise((resolve) => setTimeout(() => resolve(null), limit)),
  ])
  if (confirm) return confirm

  pending.delete(command_id)
  const resolved = await poll(command_id)
  if (!(resolved.err && resolved.err.code === "timeout")) settled.add(command_id)
  listeners.forEach((fn) => fn(resolved))
  return resolved
}

// The ledger is the source of truth when the socket lets us down.
async function poll(id, tries = 3) {
  for (let i = 0; i < tries; i++) {
    await new Promise((r) => setTimeout(r, 1500))
    try {
      const response = await fetch(`/api/commands/${id}`)
      if (!response.ok) continue
      const c = await response.json()
      if (c.status !== "pending") return { command_id: id, ...(c.result || {}) }
    } catch {
      // keep trying
    }
  }
  return { command_id: id, err: { code: "timeout" } }
}

export async function query(name, params = {}) {
  const qs = new URLSearchParams(params).toString()
  try {
    const response = await fetch(`/api/queries/${name}${qs ? `?${qs}` : ""}`)
    if (!response.ok) return { err: { code: "transport", status: response.status } }
    return { ok: await response.json() }
  } catch {
    return { err: { code: "transport" } }
  }
}

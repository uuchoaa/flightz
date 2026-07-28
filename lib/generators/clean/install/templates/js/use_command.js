// { run, pending, err } — wires command() into the three UI tiers:
// notices toast, command errors toast and stick, field errors ("invalid")
// never toast — they render in the form.
import { useCallback, useState } from "react"
import { command } from "lib/command"
import { toast } from "lib/toaster"

const MESSAGES = {
  transport: "Connection failed",
  timeout: "Still processing — check back shortly",
  not_found: "Not found",
  interpreter_down: "The interpreter is offline",
}

export function useCommand() {
  const [pending, setPending] = useState(false)
  const [err, setErr] = useState(null)

  const run = useCallback(async (name, payload, { quiet = false } = {}) => {
    setPending(true)
    setErr(null)
    const result = await command(name, payload)
    setPending(false)
    if (result.err) {
      setErr(result.err)
      if (result.err.code !== "invalid") {
        toast("err", MESSAGES[result.err.code] || `Failed: ${result.err.code}`)
      }
    } else if (!quiet && result.notice) {
      toast("ok", result.notice)
    }
    return result
  }, [])

  return { run, pending, err }
}

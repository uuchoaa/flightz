// Quick-capture: a sentence commits directly; a photo (via ImageInput,
// camera-first) resolves to proposals handed to onProposals.
import { useState } from "react"
import { html } from "lib/html"
import { useCommand } from "lib/use_command"
import { ImageInput } from "components/image_input"

export function CaptureBar({ onDone, onProposals }) {
  const [utterance, setUtterance] = useState("")
  const [imgKey, setImgKey] = useState(0)
  const { run, pending } = useCommand()

  const submitText = async (event) => {
    event.preventDefault()
    if (!utterance.trim()) return
    const result = await run("capture", { utterance })
    if (result.ok) {
      setUtterance("")
      onDone?.(result.ok)
    }
  }

  const submitPhoto = async (signedId) => {
    if (!signedId) return
    const result = await run("capture", { image: signedId }, { quiet: true, timeout: 90000 })
    setImgKey((k) => k + 1)
    if (result.ok?.proposals) onProposals?.(result.ok.proposals)
  }

  return html`
    <form onSubmit=${submitText} class="flex flex-wrap items-center gap-2">
      <input
        type="text"
        value=${utterance}
        onChange=${(e) => setUtterance(e.target.value)}
        placeholder="Describe it: what, where, condition"
        disabled=${pending}
        class="min-w-0 flex-1 rounded-lg border border-zinc-950/10 px-3 py-2 text-sm/6 dark:border-white/10 dark:bg-white/5"
      />
      <button type="submit" disabled=${pending}
              class="rounded-lg bg-zinc-900 px-3 py-2 text-sm text-white dark:bg-white dark:text-zinc-900">
        ${pending ? "..." : "Capture"}
      </button>
      <${ImageInput} key=${imgKey} disabled=${pending} onChange=${submitPhoto} />
    </form>
  `
}

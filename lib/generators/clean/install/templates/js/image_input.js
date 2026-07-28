// One image, camera-first: the primary button opens the camera, the
// secondary the file picker. Uploads via ActiveStorage direct upload;
// onChange receives the signed blob id (null on removal). Remount with a
// fresh key to reset.
import { useRef, useState } from "react"
import { DirectUpload } from "@rails/activestorage"
import { html } from "lib/html"

export function ImageInput({ onChange, disabled }) {
  const cameraRef = useRef()
  const fileRef = useRef()
  const [preview, setPreview] = useState(null)
  const [uploading, setUploading] = useState(false)

  const upload = (file) => {
    if (!file) return
    setUploading(true)
    new DirectUpload(file, "/rails/active_storage/direct_uploads").create((error, blob) => {
      setUploading(false)
      if (error) return
      setPreview(URL.createObjectURL(file))
      onChange?.(blob.signed_id)
    })
  }

  const clear = () => {
    setPreview(null)
    onChange?.(null)
  }

  if (preview) {
    return html`
      <div class="flex items-center gap-3">
        <img src=${preview} alt="" class="h-16 w-16 rounded-lg object-cover" />
        <button type="button" onClick=${clear} class="text-sm text-zinc-500 underline">
          Remove
        </button>
      </div>
    `
  }

  return html`
    <div class="flex items-center gap-2">
      <input ref=${cameraRef} type="file" accept="image/*" capture="environment" class="hidden"
             onChange=${(e) => upload(e.target.files[0])} />
      <input ref=${fileRef} type="file" accept="image/*" class="hidden"
             onChange=${(e) => upload(e.target.files[0])} />
      <button type="button" disabled=${disabled || uploading}
              onClick=${() => cameraRef.current?.click()}
              class="rounded-lg border border-zinc-950/10 px-3 py-2 text-sm sm:hidden dark:border-white/10">
        ${uploading ? "Uploading..." : "Camera"}
      </button>
      <button type="button" disabled=${disabled || uploading}
              onClick=${() => fileRef.current?.click()}
              class="rounded-lg border border-zinc-950/10 px-3 py-2 text-sm dark:border-white/10">
        ${uploading ? "Uploading..." : "File"}
      </button>
    </div>
  `
}

// htm bound to React: JSX-like tagged templates, no build step.
import htm from "htm"
import { createElement } from "react"

export const html = htm.bind(createElement)

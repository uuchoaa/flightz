import { createElement } from "react"
import { createRoot } from "react-dom/client"
import { connectCommands } from "lib/command"
import { App } from "components/app"

connectCommands()

const el = document.getElementById("app")
if (el) createRoot(el).render(createElement(App))

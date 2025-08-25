import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    this.adjustHeaderWidth()
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.adjustHeaderWidth()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.adjustHeaderWidth()
  }

  adjustHeaderWidth() {
    const header = document.querySelector('[data-documents-panel-header]')
    if (header) {
      if (this.panelTarget.classList.contains('hidden')) {
        header.style.right = '1rem' // right-4
      } else {
        header.style.right = '21rem' // right-4 + w-80 (20rem) + gap
      }
    }
  }
}

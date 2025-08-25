import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash-message"
export default class extends Controller {
  static values = { timeout: Number }

  connect() {
    if (this.timeoutValue) {
      setTimeout(() => {
        this.hide()
      }, this.timeoutValue)
    }
  }

  hide() {
    this.element.classList.add('opacity-0', 'transform', 'translate-x-full')
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  click() {
    this.hide()
  }
}

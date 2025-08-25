import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  clearInput() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitTarget.click()
    }
  }
}

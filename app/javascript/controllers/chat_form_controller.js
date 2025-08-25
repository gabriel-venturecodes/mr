import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "textInput"]
  static outlets = ["attachment-menu"]

  connect() {
    // Listen for successful turbo stream responses
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSubmitEnd(event) {
    // Only clear if the submission was successful
    if (event.detail.success) {
      this.clearForm()
    }
  }

  clearForm() {
    // Clear the text input
    if (this.hasTextInputTarget) {
      this.textInputTarget.value = ""
      // Trigger resize event to reset textarea height
      this.textInputTarget.dispatchEvent(new Event('input'))
    }

    // Clear attachment menu if available
    if (this.hasAttachmentMenuOutlet) {
      this.attachmentMenuOutlet.clearForm()
    }
  }
}

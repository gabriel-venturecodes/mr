import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
  static targets = ["content", "arrow"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    
    // Rotate the arrow
    if (this.contentTarget.classList.contains("hidden")) {
      this.arrowTarget.style.transform = "rotate(0deg)"
    } else {
      this.arrowTarget.style.transform = "rotate(180deg)"
    }
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { hypothesisId: String }

  selectInsight() {
    console.log("Selecting insight:", this.hypothesisIdValue)
    
    // Send the selection to the server using Turbo
    this.sendInsightSelection()
  }

  async sendInsightSelection() {
    try {
      const response = await fetch('/select_insight', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: new URLSearchParams({
          hypothesis_id: this.hypothesisIdValue
        })
      })

      if (response.ok) {
        const result = await response.text()
        
        // Let Turbo handle the stream response
        Turbo.renderStreamMessage(result)
        
        // Scroll to the bottom after a short delay
        setTimeout(() => {
          window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' })
        }, 100)
        
      } else {
        console.error('Failed to select insight')
      }
    } catch (error) {
      console.error('Error selecting insight:', error)
    }
  }
}

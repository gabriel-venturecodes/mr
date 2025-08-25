import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  showAllInsights() {
    // Toggle to show all insights in detail view
    this.toggleInsightsDetail()
  }

  showDocuments() {
    // Show documents modal or section
    const event = new CustomEvent('show-documents', {
      detail: { source: 'insights-overview' }
    })
    window.dispatchEvent(event)
  }

  askNewQuestion() {
    // Focus on the question input
    const questionInput = document.querySelector('[data-chat-form-target="question"]')
    if (questionInput) {
      questionInput.focus()
      questionInput.scrollIntoView({ behavior: 'smooth' })
    }
  }

  toggleInsightsDetail() {
    // Find all insight cards and toggle their detail view
    const insightCards = document.querySelectorAll('[data-controller*="insight-selector"]')
    
    insightCards.forEach(card => {
      const detailSection = card.querySelector('.insight-detail-section')
      if (detailSection) {
        detailSection.classList.toggle('hidden')
      }
    })
  }
}

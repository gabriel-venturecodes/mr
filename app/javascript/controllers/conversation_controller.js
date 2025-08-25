import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  askFollowUp() {
    // Focus on the chat input and prepare for follow-up
    const chatInput = document.querySelector('[data-chat-form-target="question"]')
    if (chatInput) {
      chatInput.focus()
      chatInput.placeholder = "Ask a follow-up question about this insight..."
      
      // Scroll to the input
      chatInput.scrollIntoView({ behavior: 'smooth' })
    }
  }

  uploadMore() {
    // Trigger file upload modal or focus on file input
    const fileInput = document.querySelector('[data-chat-form-target="fileInput"]')
    if (fileInput) {
      fileInput.click()
    }
    
    // Also focus on the question input with context
    const chatInput = document.querySelector('[data-chat-form-target="question"]')
    if (chatInput) {
      chatInput.placeholder = "Upload documents and ask how they relate to this insight..."
    }
  }

  seeAlternatives() {
    // Show other insights that weren't selected
    this.toggleAlternativeInsights()
  }

  suggestQuestion(event) {
    const question = event.currentTarget.dataset.question
    const chatInput = document.querySelector('[data-chat-form-target="question"]')
    
    if (chatInput && question) {
      chatInput.value = question
      chatInput.focus()
      
      // Scroll to the input
      chatInput.scrollIntoView({ behavior: 'smooth' })
    }
  }

  toggleAlternativeInsights() {
    // Find and toggle alternative insights section
    let alternativesSection = document.getElementById('alternative-insights')
    
    if (!alternativesSection) {
      // Create the alternatives section if it doesn't exist
      this.createAlternativesSection()
    } else {
      alternativesSection.classList.toggle('hidden')
    }
  }

  createAlternativesSection() {
    // This would dynamically load other insights
    // For now, we'll just scroll to show there are other insights available
    const hint = document.createElement('div')
    hint.id = 'alternative-insights'
    hint.className = 'mt-4 p-4 bg-blue-900 bg-opacity-20 border border-blue-600 rounded-lg'
    hint.innerHTML = `
      <div class="flex items-center space-x-2">
        <svg class="w-5 h-5 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        <span class="text-blue-200 font-medium">Other insights are available</span>
      </div>
      <p class="text-blue-100 text-sm mt-2">
        There were additional insights from your analysis. Start a new question to explore them, 
        or continue deepening this current research path.
      </p>
    `
    
    // Insert after the current insight
    this.element.appendChild(hint)
  }
}

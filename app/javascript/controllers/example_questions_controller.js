import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="example-questions"
export default class extends Controller {
  fillQuestion(event) {
    // Get just the text content, stripping any HTML formatting
    const question = event.target.textContent.trim().replace(/"/g, '')
    const textarea = document.querySelector('textarea[name="brief"]')
    
    if (textarea) {
      // Clear any existing value and set the clean question text
      textarea.value = ""
      textarea.value = question
      textarea.focus()
      
      // Trigger resize and input events
      const inputEvent = new Event('input', { bubbles: true })
      textarea.dispatchEvent(inputEvent)
      
      // Ensure the textarea resizes properly
      if (textarea.scrollHeight > textarea.clientHeight) {
        textarea.style.height = 'auto'
        textarea.style.height = textarea.scrollHeight + 'px'
      }
    }
  }
}

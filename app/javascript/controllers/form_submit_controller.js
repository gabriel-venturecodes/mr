import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-submit"  
export default class extends Controller {
  submit(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      event.preventDefault()
      this.element.closest('form').requestSubmit()
    }
  }
}

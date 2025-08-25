import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "selectedFiles", "fileList"]

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle("hidden")
  }

  filesSelected(event) {
    const files = event.target.files
    
    if (files.length > 0) {
      this.showSelectedFiles(files)
      this.hideMenu()
    }
  }

  showSelectedFiles(files) {
    this.selectedFilesTarget.classList.remove("hidden")
    
    // Clear previous file list
    this.fileListTarget.innerHTML = ""
    
    // Add each file to the list
    Array.from(files).forEach((file, index) => {
      const fileItem = document.createElement("div")
      fileItem.className = "flex items-center justify-between bg-gray-600 rounded-lg px-3 py-2"
      fileItem.innerHTML = `
        <div class="flex items-center space-x-2">
          <svg class="w-4 h-4 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
          </svg>
          <span class="text-white text-sm font-medium truncate">${file.name}</span>
        </div>
        <div class="flex items-center space-x-2">
          <span class="text-gray-300 text-xs">${this.formatFileSize(file.size)}</span>
          <span class="text-green-400 text-xs">✓</span>
        </div>
      `
      this.fileListTarget.appendChild(fileItem)
    })
  }

  clearFiles(event) {
    event.preventDefault()
    
    // Reset the file input
    const fileInput = this.element.querySelector('input[type="file"]')
    if (fileInput) {
      fileInput.value = ""
    }
    
    // Hide the selected files section
    this.selectedFilesTarget.classList.add("hidden")
  }

  // Clear form after successful submission
  clearForm() {
    // Reset the file input
    const fileInput = this.element.querySelector('input[type="file"]')
    if (fileInput) {
      fileInput.value = ""
    }
    
    // Hide the selected files section
    this.selectedFilesTarget.classList.add("hidden")
    
    // Clear the text input
    const textInput = this.element.querySelector('textarea[name="brief"]')
    if (textInput) {
      textInput.value = ""
      // Trigger resize event to reset height
      textInput.dispatchEvent(new Event('input'))
    }
  }

  hideMenu() {
    this.menuTarget.classList.add("hidden")
  }

  // Hide menu when clicking outside
  connect() {
    this.outsideClickHandler = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideMenu()
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
  }
}

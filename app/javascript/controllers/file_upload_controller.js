import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectedFiles", "fileList"]

  filesSelected(event) {
    const files = event.target.files
    
    if (files.length > 0) {
      this.showSelectedFiles(files)
    } else {
      this.hideSelectedFiles()
    }
  }

  showSelectedFiles(files) {
    // Show the selected files section
    this.selectedFilesTarget.classList.remove("hidden")
    
    // Clear previous file list
    this.fileListTarget.innerHTML = ""
    
    // Add each file to the list
    Array.from(files).forEach((file, index) => {
      const fileItem = document.createElement("div")
      fileItem.className = "flex items-center justify-between bg-gray-700 rounded px-2 py-1"
      fileItem.innerHTML = `
        <span class="truncate">${file.name}</span>
        <span class="text-gray-500 ml-2">${this.formatFileSize(file.size)}</span>
      `
      this.fileListTarget.appendChild(fileItem)
    })
  }

  hideSelectedFiles() {
    this.selectedFilesTarget.classList.add("hidden")
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
  }
}

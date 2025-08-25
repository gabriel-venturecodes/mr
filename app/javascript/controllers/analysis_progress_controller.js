import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statusMessage", "progressPercent", "progressBar", "agentActivity", "funMessage"]
  static values = { analysisId: String }

  connect() {
    console.log("Analysis progress controller connected")
    this.startPolling()
    this.startFunMessages()
  }

  disconnect() {
    this.stopPolling()
    this.stopFunMessages()
  }

  startPolling() {
    this.pollInterval = setInterval(() => {
      this.checkProgress()
    }, 2000) // Poll every 2 seconds
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
    }
  }

  startFunMessages() {
    const messages = [
      "💡 Did you know? Our agents process about 1,000 words per second!",
      "🔍 Each document is analyzed through multiple AI perspectives...",
      "🧠 The Critic Agent is double-checking every claim for accuracy...",
      "📊 Building knowledge graphs to connect insights...",
      "⚡ Semantic similarity analysis in progress...",
      "🎯 Generating evidence-backed hypotheses...",
      "🔬 Quality control: Validating all claims against source material..."
    ]

    let messageIndex = 0
    this.funMessageInterval = setInterval(() => {
      if (this.hasFunMessageTarget) {
        this.funMessageTarget.textContent = messages[messageIndex]
        messageIndex = (messageIndex + 1) % messages.length
      }
    }, 4000) // Change message every 4 seconds
  }

  stopFunMessages() {
    if (this.funMessageInterval) {
      clearInterval(this.funMessageInterval)
    }
  }

  async checkProgress() {
    try {
      const response = await fetch(`/analysis_status?analysis_id=${this.analysisIdValue}`)
      const data = await response.json()

      if (data.error) {
        console.error("Analysis error:", data.error)
        this.handleError(data.error)
        return
      }

      // Update progress
      this.updateProgress(data.progress, data.message)
      this.updateAgentActivity(data.progress)

      // Check if completed
      if (data.status === 'completed') {
        this.stopPolling()
        this.handleCompletion(data.hypotheses)
      } else if (data.status === 'failed') {
        this.stopPolling()
        this.handleError(data.error)
      }

    } catch (error) {
      console.error("Failed to check analysis progress:", error)
    }
  }

  updateProgress(progress, message) {
    if (this.hasProgressPercentTarget) {
      this.progressPercentTarget.textContent = `${progress}%`
    }
    
    if (this.hasStatusMessageTarget && message) {
      this.statusMessageTarget.textContent = message
    }
    
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progress}%`
    }
  }

  updateAgentActivity(progress) {
    if (!this.hasAgentActivityTarget) return

    const activities = []

    if (progress >= 10) {
      activities.push({
        agent: "Orchestrator Agent",
        activity: "Coordinating analysis pipeline",
        status: progress >= 20 ? "completed" : "active"
      })
    }

    if (progress >= 20) {
      activities.push({
        agent: "Retrieval Agent", 
        activity: "Splitting documents into chunks",
        status: progress >= 40 ? "completed" : "active"
      })
    }

    if (progress >= 40) {
      activities.push({
        agent: "Analysis Agent",
        activity: "Extracting entities and relationships", 
        status: progress >= 60 ? "completed" : "active"
      })
    }

    if (progress >= 60) {
      activities.push({
        agent: "Synthesis Agent",
        activity: "Generating hypotheses",
        status: progress >= 80 ? "completed" : "active"
      })
    }

    if (progress >= 80) {
      activities.push({
        agent: "Critic Agent",
        activity: "Validating evidence",
        status: progress >= 100 ? "completed" : "active"
      })
    }

    // Update the activity display
    this.agentActivityTarget.innerHTML = activities.map(activity => {
      const iconClass = activity.status === "completed" ? "bg-green-400" : "bg-blue-400 animate-pulse"
      const icon = activity.status === "completed" ? "✅" : "🔄"
      
      return `
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 ${iconClass} rounded-full"></div>
          <span>${icon} ${activity.agent}: ${activity.activity}</span>
        </div>
      `
    }).join("")
  }

  handleCompletion(hypotheses) {
    // Redirect to results or update the view
    window.location.reload() // Simple approach for now
  }

  handleError(error) {
    console.error("Analysis failed:", error)
    this.element.innerHTML = `
      <div class="text-red-400 p-4">
        <h3 class="font-bold">Analysis Failed</h3>
        <p>${error}</p>
      </div>
    `
  }
}

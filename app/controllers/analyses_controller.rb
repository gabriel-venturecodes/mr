class AnalysesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_analysis, only: [:show, :destroy]

  def show
    @hypotheses = @analysis.hypotheses.verified  # For the analysis results partial

    # Get all documents for sidebar and documents panel
    @documents = Document.where(processing_status: 'completed')
    @recent_analyses = Analysis.includes(:hypotheses)
                              .where(analyses: { status: 'completed' })
                              .order(created_at: :desc)
                              .limit(5)

    render 'chat/index'
  end

  def index
    @analyses = Analysis.where(status: 'completed').order(created_at: :desc)
    @documents = Document.where(processing_status: 'completed')
    @recent_analyses = @analyses.limit(5)

    render 'chat/index'
  end

  def destroy
    # Log what we're about to delete
    Rails.logger.info "Deleting analysis #{@analysis.id} with #{@analysis.hypotheses.count} hypotheses"

    # Delete the analysis (this will cascade delete hypotheses and claims)
    analysis_brief = @analysis.brief
    @analysis.destroy!

    respond_to do |format|
      format.html {
        redirect_to root_path, notice: "Analysis '#{analysis_brief[0..50]}...' deleted successfully"
      }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("flash",
          partial: "shared/flash_message", 
          locals: { message: "Analysis deleted successfully", type: "success" }
        )
      }
    end
  rescue => e
    Rails.logger.error "Failed to delete analysis: #{e.message}"
    
    respond_to do |format|
      format.html {
        redirect_to root_path, alert: "Failed to delete analysis: #{e.message}"
      }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("flash",
          partial: "shared/flash_message",
          locals: { message: "Failed to delete analysis: #{e.message}", type: "error" }
        )
      }
    end
  end

  private

  def find_analysis
    @analysis = Analysis.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html {
        redirect_to root_path, alert: "Analysis not found"
      }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("flash",
          partial: "shared/flash_message",
          locals: { message: "Analysis not found", type: "error" }
        )
      }
    end
  end
end

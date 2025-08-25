class HypothesesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_hypothesis, only: [:show, :destroy]

  def show
    @hypotheses = [@hypothesis]  # For the analysis results partial

    # Get all documents for sidebar and documents panel
    @documents = Document.where(processing_status: 'completed')
    @recent_hypotheses = Hypothesis.where(status: 'verified').order(created_at: :desc).limit(5)

    render 'chat/index'
  end

  def index
    @hypotheses = Hypothesis.where(status: 'verified').order(created_at: :desc)
    @documents = Document.where(processing_status: 'completed')
    @recent_hypotheses = @hypotheses.limit(5)

    render 'chat/index'
  end

  def destroy
    # Get associated documents through claims citations
    cited_chunk_ids = @hypothesis.claims.pluck(:citation_chunk_ids).flatten.uniq.compact

    if cited_chunk_ids.any?
      cited_chunks = Chunk.where(id: cited_chunk_ids)
      document_ids = cited_chunks.pluck(:document_id).uniq

      # Log what we're about to delete
      Rails.logger.info "Deleting hypothesis #{@hypothesis.id} with #{@hypothesis.claims.count} claims"
      Rails.logger.info "Will also delete #{document_ids.count} associated documents: #{document_ids}"

      # Delete associated documents and their chunks/entities/relations
      documents_deleted = Document.where(id: document_ids).destroy_all

      Rails.logger.info "Deleted #{documents_deleted.count} documents and their associated data"
    else
      Rails.logger.info "Deleting hypothesis #{@hypothesis.id} with no associated documents"
    end

    # Delete the hypothesis (this will cascade delete claims)
    hypothesis_title = @hypothesis.title
    @hypothesis.destroy!

    respond_to do |format|
      format.html {
        redirect_to root_path, notice: "Analysis '#{hypothesis_title}' and associated documents deleted successfully"
      }
      format.turbo_stream {
        redirect_to root_path, notice: "Analysis '#{hypothesis_title}' and associated documents deleted successfully"
      }
    end
  rescue => e
    Rails.logger.error "Failed to delete hypothesis: #{e.message}"

    respond_to do |format|
      format.html {
        redirect_to root_path, alert: "Failed to delete analysis: #{e.message}"
      }
      format.turbo_stream {
        redirect_to root_path, alert: "Failed to delete analysis: #{e.message}"
      }
    end
  end

  private

  def find_hypothesis
    @hypothesis = Hypothesis.find(params[:id])
  end
end

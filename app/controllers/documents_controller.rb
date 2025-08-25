class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: [:show]

  def index
    @documents = Document.all.order(:created_at)
  end

  def show
    @chunks = @document.chunks.order(:position)
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      # Start processing the document in the background
      ProcessDocumentJob.perform_later(@document.id) if defined?(ProcessDocumentJob)

      redirect_to @document, notice: 'Document was successfully uploaded.'
    else
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def upload
    unless params[:files].present?
      render json: { error: "No files provided" }, status: :bad_request
      return
    end

    uploaded_documents = []
    errors = []

    params[:files].each do |file|
      begin
        document = create_document_from_file(file)
        if document.persisted?
          uploaded_documents << document
          # Start processing immediately for demo
          process_document_sync(document)
        else
          errors << "Failed to upload #{file.original_filename}: #{document.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Error processing #{file.original_filename}: #{e.message}"
      end
    end

    if errors.any?
      render json: {
        message: "Some files failed to upload",
        errors: errors,
        uploaded: uploaded_documents.count
      }, status: :partial_content
    else
      render json: {
        message: "#{uploaded_documents.count} files uploaded successfully",
        documents: uploaded_documents.map { |d| { id: d.id, title: d.title, status: d.processing_status } }
      }
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title, :source_uri, :mime_type, :meta)
  end

  def create_document_from_file(file)
    mime_type = file.content_type || 'application/octet-stream'

    # Extract text from file based on type
    extracted_text = extract_text_from_file(file, mime_type)

    Document.create!(
      title: file.original_filename,
      source_uri: file.original_filename,
      mime_type: mime_type,
      processing_status: 'pending',
      meta: {
        file_size: file.size,
        extracted_text: extracted_text,
        upload_timestamp: Time.current
      }
    )
  end

  def extract_text_from_file(file, mime_type)
    case mime_type
    when 'text/csv'
      extract_csv_text(file)
    when 'application/json'
      extract_json_text(file)
    when 'application/pdf'
      extract_pdf_text(file)
    when 'text/plain'
      file.read.force_encoding('UTF-8')
    else
      # Try to read as text
      begin
        file.read.force_encoding('UTF-8')
      rescue
        ""
      end
    end
  end

  def extract_csv_text(file)
    require 'csv'
    text_parts = []

    CSV.foreach(file.path, headers: true) do |row|
      # Convert each row to a readable sentence
      row_text = row.to_h.map { |k, v| "#{k}: #{v}" }.join(", ")
      text_parts << row_text
    end

    text_parts.join("\n")
  rescue => e
    Rails.logger.error "Failed to parse CSV: #{e.message}"
    ""
  end

  def extract_json_text(file)
    json_data = JSON.parse(file.read)

    # Convert JSON to readable text
    if json_data.is_a?(Array)
      json_data.map { |item| json_to_text(item) }.join("\n")
    else
      json_to_text(json_data)
    end
  rescue => e
    Rails.logger.error "Failed to parse JSON: #{e.message}"
    ""
  end

  def extract_pdf_text(file)
    begin
      require 'pdf-reader'
      reader = PDF::Reader.new(file.path)
      reader.pages.map(&:text).join("\n")
    rescue => e
      Rails.logger.error "Failed to extract PDF text: #{e.message}"
      ""
    end
  end

  def json_to_text(obj, prefix = "")
    case obj
    when Hash
      obj.map { |k, v| "#{prefix}#{k}: #{json_to_text(v)}" }.join(", ")
    when Array
      obj.map.with_index { |item, i| json_to_text(item, "#{prefix}[#{i}] ") }.join("; ")
    else
      obj.to_s
    end
  end

  def process_document_sync(document)
    # For demo purposes, process synchronously
    # In production, this would be a background job
    begin
      document.update!(processing_status: 'processing')

      # Chunk the document
      chunks = ChunkingService.chunk_document(document)

      # Extract entities from chunks
      entities = EntityExtractionService.extract_from_chunks(chunks) if chunks.any?

      # Extract relations from chunks
      relations = RelationExtractionService.extract_from_chunks(chunks) if chunks.any?

      document.update!(processing_status: 'completed')

      Rails.logger.info "Processed document #{document.id}: #{chunks.count} chunks, #{entities&.count || 0} entities, #{relations&.count || 0} relations"
    rescue => e
      Rails.logger.error "Failed to process document #{document.id}: #{e.message}"
      document.update!(processing_status: 'failed')
    end
  end
end

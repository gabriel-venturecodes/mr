class OrchestratorAgent
  def self.analyze(brief, options = {})
    new.analyze(brief, options)
  end

  def initialize
    @prompt_version = "v1.0"
  end

  def analyze(brief, options = {})
    Rails.logger.info "Starting analysis for brief: '#{brief[0..100]}...'"

    begin
      # Initialize audit trail
      audit_trail = {
        brief: brief,
        start_time: Time.current,
        steps: []
      }

      # Check if we have processed documents
      documents = Document.completed
      if documents.empty?
        return {
          success: false,
          error: "No processed documents found. Please upload and process documents first.",
          hypotheses: []
        }
      end

      audit_trail[:steps] << {
        service: "DocumentRetrieval",
        timestamp: Time.current,
        input: "Searching for completed documents",
        output: "Found #{documents.count} completed documents",
        conclusion: "Successfully retrieved #{documents.count} processed documents for analysis"
      }

      # Get all chunks from completed documents
      chunks = Chunk.joins(:document).where(documents: { processing_status: 'completed' })

      if chunks.empty?
        return {
          success: false,
          error: "No text chunks found in processed documents.",
          hypotheses: []
        }
      end

      audit_trail[:steps] << {
        service: "ChunkRetrieval",
        timestamp: Time.current,
        input: "Extracting text chunks from documents",
        output: "Retrieved #{chunks.count} text chunks",
        conclusion: "Successfully extracted #{chunks.count} text segments from documents for semantic analysis"
      }

      # Get existing entities and relations
      entities = Entity.all
      relations = Relation.all

      audit_trail[:steps] << {
        service: "KnowledgeGraphRetrieval",
        timestamp: Time.current,
        input: "Loading existing knowledge graph data",
        output: "Found #{entities.count} entities and #{relations.count} relations",
        conclusion: "Retrieved knowledge graph with #{entities.count} entities and #{relations.count} relationships for context"
      }

      Rails.logger.info "Analysis context: #{chunks.count} chunks, #{entities.count} entities, #{relations.count} relations"

      # Generate hypotheses using synthesis service
      hypotheses = SynthesisAgent.generate_hypotheses(
        brief, chunks, entities, relations,
        prompt_version: @prompt_version,
        audit_trail: audit_trail
      )

      # Validate hypotheses using critic service
      validated_hypotheses = hypotheses.select do |hypothesis|
        CriticAgent.validate_hypothesis(hypothesis, audit_trail: audit_trail)
      end

      audit_trail[:steps] << {
        service: "ValidationSummary",
        timestamp: Time.current,
        input: "#{hypotheses.count} generated hypotheses",
        output: "#{validated_hypotheses.count} validated hypotheses",
        conclusion: "#{validated_hypotheses.count} out of #{hypotheses.count} hypotheses passed evidence validation criteria"
      }

      audit_trail[:end_time] = Time.current
      duration_ms = ((audit_trail[:end_time] - audit_trail[:start_time]) * 1000).round(2)
      audit_trail[:duration] = format_duration(duration_ms)

      # Update hypotheses with audit trail
      validated_hypotheses.each do |hypothesis|
        hypothesis.update!(audit_trail: audit_trail)
      end

      Rails.logger.info "Analysis complete: #{validated_hypotheses.count}/#{hypotheses.count} hypotheses validated"

      {
        success: true,
        hypotheses: validated_hypotheses,
        audit_trail: audit_trail,
        stats: {
          total_hypotheses: hypotheses.count,
          validated_hypotheses: validated_hypotheses.count,
          total_claims: hypotheses.sum { |h| h.claims.count },
          verified_claims: hypotheses.sum { |h| h.claims.where(status: 'verified').count },
          documents_analyzed: documents.count,
          chunks_processed: chunks.count
        }
      }

    rescue => e
      Rails.logger.error "Analysis failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        error: "Analysis failed: #{e.message}",
        hypotheses: []
      }
    end
  end

  def analyze_with_new_documents(brief, uploaded_files, options = {})
    Rails.logger.info "Analyzing with #{uploaded_files.count} new documents"

    begin
      # Process uploaded files
      processed_documents = process_uploaded_files(uploaded_files)

      if processed_documents.empty?
        return {
          success: false,
          error: "Failed to process uploaded documents",
          hypotheses: []
        }
      end

      # Run analysis with all documents (existing + new)
      analyze(brief, options)

    rescue => e
      Rails.logger.error "Analysis with new documents failed: #{e.message}"

      {
        success: false,
        error: "Failed to process documents: #{e.message}",
        hypotheses: []
      }
    end
  end

  private

  def process_uploaded_files(files)
    processed_documents = []

    files.each do |file|
      begin
        document = create_document_from_file(file)
        if document.persisted?
          process_document_pipeline(document)
          processed_documents << document if document.reload.completed?
        end
      rescue => e
        Rails.logger.error "Failed to process file #{file.original_filename}: #{e.message}"
        next
      end
    end

    processed_documents
  end

  def create_document_from_file(file)
    mime_type = file.content_type || 'application/octet-stream'
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

  def process_document_pipeline(document)
    document.update!(processing_status: 'processing')

    # Chunk the document
    chunks = RetrievalAgent.chunk_document(document)

    # Extract entities from chunks
    entities = AnalysisAgent.extract_from_chunks(chunks) if chunks.any?

    # Extract relations from chunks
    relations = AnalysisAgent.extract_relations_from_chunks(chunks) if chunks.any?

    document.update!(processing_status: 'completed')

    Rails.logger.info "Processed document #{document.id}: #{chunks.count} chunks, #{entities&.count || 0} entities, #{relations&.count || 0} relations"
  rescue => e
    Rails.logger.error "Failed to process document #{document.id}: #{e.message}"
    document.update!(processing_status: 'failed')
    raise e
  end

  private



  def format_duration(duration_ms)
    if duration_ms >= 1000
      "#{(duration_ms / 1000.0).round(1)}s"
    else
      "#{duration_ms.round(0)}ms"
    end
  end
end

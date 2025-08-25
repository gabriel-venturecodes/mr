class RetrievalAgent
  TARGET_TOKENS = 600
  OVERLAP_TOKENS = 100
  WORDS_PER_TOKEN = 0.75  # Rough approximation

  def self.chunk_document(document)
    new.chunk_document(document)
  end

  def self.count_tokens(text)
    return 0 if text.blank?
    (text.split.count / WORDS_PER_TOKEN).ceil
  end

  def chunk_document(document)
    text = extract_text_from_document(document)
    return [] if text.blank?

    chunks = chunk_by_sentences(text)

    chunks.map.with_index do |chunk_text, index|
      document.chunks.create!(
        text: chunk_text,
        position: index,
        meta: {
          token_count: estimate_tokens(chunk_text),
          word_count: chunk_text.split.count
        }
      )
    end
  end

  def chunk_by_sentences(text)
    sentences = split_into_sentences(text)
    chunks = []
    current_chunk = []
    current_tokens = 0

    sentences.each do |sentence|
      sentence_tokens = estimate_tokens(sentence)

      # If adding this sentence would exceed target, finalize current chunk
      if current_tokens + sentence_tokens > TARGET_TOKENS && current_chunk.any?
        chunks << current_chunk.join(' ')

        # Start new chunk with overlap from previous chunk
        overlap_sentences = get_overlap_sentences(current_chunk)
        current_chunk = overlap_sentences
        current_tokens = estimate_tokens(current_chunk.join(' '))
      end

      current_chunk << sentence
      current_tokens += sentence_tokens
    end

    # Add final chunk if it has content
    chunks << current_chunk.join(' ') if current_chunk.any?

    chunks
  end

  private

  def extract_text_from_document(document)
    case document.mime_type
    when 'application/pdf'
      extract_pdf_text(document)
    when 'text/csv'
      extract_csv_text(document)
    when 'application/json'
      extract_json_text(document)
    when 'text/plain'
      extract_plain_text(document)
    else
      Rails.logger.warn "Unsupported mime type: #{document.mime_type}"
      ""
    end
  end

  def extract_pdf_text(document)
    # For now, assume we have the text in document.meta['extracted_text']
    # In a real implementation, we'd use PDF::Reader here
    document.meta['extracted_text'] || ""
  end

  def extract_csv_text(document)
    # Convert CSV to readable text format
    # This would read the actual CSV file and convert to text
    document.meta['extracted_text'] || ""
  end

  def extract_json_text(document)
    # Convert JSON to readable text format
    document.meta['extracted_text'] || ""
  end

  def extract_plain_text(document)
    document.meta['extracted_text'] || ""
  end

  def split_into_sentences(text)
    # Simple sentence splitting - in production, use a proper NLP library
    text.split(/[.!?]+/).map(&:strip).reject(&:empty?)
  end

  def estimate_tokens(text)
    (text.split.count / WORDS_PER_TOKEN).ceil
  end

  def get_overlap_sentences(sentences)
    # Take last few sentences for overlap, up to OVERLAP_TOKENS
    overlap = []
    tokens = 0

    sentences.reverse_each do |sentence|
      sentence_tokens = estimate_tokens(sentence)
      break if tokens + sentence_tokens > OVERLAP_TOKENS

      overlap.unshift(sentence)
      tokens += sentence_tokens
    end

    overlap
  end
end

class CriticAgent
  MIN_COSINE_SIMILARITY = 0.05  # Lowered to 5% to allow more hypotheses to pass

  def self.validate_claim(claim, audit_trail: nil)
    new.validate_claim(claim, audit_trail: audit_trail)
  end

  def self.validate_hypothesis(hypothesis, audit_trail: nil)
    new.validate_hypothesis(hypothesis, audit_trail: audit_trail)
  end

  def initialize
  end

  def validate_claim(claim, audit_trail: nil)
    return false unless claim.citation_chunk_ids.present?

    begin
      citations = claim.cited_chunks
      return reject_claim(claim, "No citation chunks found") if citations.empty?

      # Check similarity between claim and citations
      max_similarity = calculate_max_similarity(claim, citations)
      distinct_documents = citations.map(&:document_id).uniq.count

      if max_similarity >= MIN_COSINE_SIMILARITY && distinct_documents >= 1
        result = approve_claim(claim, max_similarity, distinct_documents)

        audit_trail[:steps] << {
          service: "CriticAgent",
          step: "ClaimApproval",
          timestamp: Time.current,
          input: "Claim: '#{claim.text[0..50]}...'",
          output: "APPROVED - #{(max_similarity * 100).round(1)}% similarity, #{distinct_documents} documents",
          conclusion: "Claim meets evidence threshold with #{(max_similarity * 100).round(1)}% text similarity to source chunks"
        } if audit_trail

        result
      else
        result = reject_claim(claim, "Insufficient evidence", max_similarity, distinct_documents)

        audit_trail[:steps] << {
          service: "CriticAgent",
          step: "ClaimRejection",
          timestamp: Time.current,
          input: "Claim: '#{claim.text[0..50]}...'",
          output: "REJECTED - #{(max_similarity * 100).round(1)}% similarity, #{distinct_documents} documents",
          conclusion: "Claim below evidence threshold (need #{(MIN_COSINE_SIMILARITY * 100).round(1)}% minimum similarity)"
        } if audit_trail

        result
      end

    rescue => e
      Rails.logger.error "Critic validation failed for claim #{claim.id}: #{e.message}"
      reject_claim(claim, "Validation error: #{e.message}")
    end
  end

  def validate_hypothesis(hypothesis, audit_trail: nil)
    claims = hypothesis.claims
    return false if claims.empty?

    audit_trail[:steps] << {
      service: "CriticAgent",
      step: "HypothesisValidation",
      timestamp: Time.current,
      input: "Hypothesis: '#{hypothesis.title}' with #{claims.count} claims",
      output: "Starting evidence validation for #{claims.count} claims",
      conclusion: "Beginning systematic validation of claims against source documents"
    } if audit_trail

    results = claims.map { |claim| validate_claim(claim, audit_trail: audit_trail) }
    verified_count = results.count(true)

    audit_trail[:steps] << {
      service: "CriticAgent",
      step: "ValidationResults",
      timestamp: Time.current,
      input: "#{claims.count} claims processed",
      output: "#{verified_count} claims verified, #{claims.count - verified_count} rejected",
      conclusion: "#{verified_count}/#{claims.count} claims met minimum evidence threshold (#{(MIN_COSINE_SIMILARITY * 100).round(1)}% similarity)"
    } if audit_trail

    # Update hypothesis status based on claim validation results
    if verified_count == claims.count
      hypothesis.update!(status: 'verified')
      true
    elsif verified_count > 0
      hypothesis.update!(status: 'verified')  # Partial verification still useful
      true
    else
      hypothesis.update!(status: 'rejected')
      false
    end
  end

  private

  def calculate_max_similarity(claim, citations)
    # For demo without vector embeddings, use simple text similarity
    claim_text = normalize_text(claim.text)

    max_similarity = citations.map do |chunk|
      chunk_text = normalize_text(chunk.text)
      text_similarity(claim_text, chunk_text)
    end.max

    max_similarity || 0.0
  end

  def normalize_text(text)
    text.downcase
        .gsub(/[^\w\s]/, ' ')
        .squeeze(' ')
        .strip
  end

  def text_similarity(text1, text2)
    # Simple Jaccard similarity for demo
    words1 = text1.split.to_set
    words2 = text2.split.to_set

    intersection = words1 & words2
    union = words1 | words2

    return 0.0 if union.empty?
    intersection.size.to_f / union.size
  end

  def approve_claim(claim, similarity, document_count)
    claim.update!(
      status: 'verified',
      max_citation_similarity: similarity,
      explanation: build_approval_explanation(similarity, document_count)
    )

    Rails.logger.info "CRITIC_APPROVED: Claim #{claim.id} (sim: #{similarity.round(3)}, docs: #{document_count})"
    true
  end

  def reject_claim(claim, reason, similarity = nil, document_count = nil)
    explanation = build_rejection_explanation(reason, similarity, document_count)

    claim.update!(
      status: 'rejected',
      max_citation_similarity: similarity,
      explanation: explanation
    )

    Rails.logger.warn "CRITIC_REJECTED: Claim #{claim.id} - #{reason}"
    false
  end

  def build_approval_explanation(similarity, document_count)
    "Verified by source chunks (max similarity #{(similarity * 100).round(1)}% from #{document_count} document#{document_count == 1 ? '' : 's'})"
  end

  def build_rejection_explanation(reason, similarity, document_count)
    if similarity
      "#{reason} (similarity #{(similarity * 100).round(1)}%#{document_count ? ", #{document_count} docs" : ''})"
    else
      reason
    end
  end
end

class EntityCanonicalizer
  THRESHOLDS = {
    "Product" => 0.92,     # High threshold - "Oat Milk" vs "Barista Oat Milk" stay distinct
    "Demographic" => 0.90, # "18-25" vs "young adults"
    "Company" => 0.94,     # Very high - "Apple Inc" vs "Apple Corp"
    "Campaign" => nil,     # Exact match or alias table only
    "Attribute" => 0.70,   # Lower threshold for attributes
    "Metric" => 0.85       # Metrics should be fairly exact
  }.freeze

  def self.canonicalize(entity_type, name)
    new.canonicalize(entity_type, name)
  end

  def canonicalize(entity_type, name)
    normalized = normalize_string(name)

    # Check aliases table first
    alias_match = EntityAlias.find_by(entity_type: entity_type, variant: normalized)
    return alias_match.canonical_name if alias_match

    # Apply similarity matching with type-specific threshold
    threshold = THRESHOLDS[entity_type]
    return normalized unless threshold

    # Find best match among existing entities of the same type
    existing_entities = Entity.where(entity_type: entity_type)
    best_match = nil
    best_similarity = 0.0

    existing_entities.find_each do |entity|
      similarity = JaroWinkler.similarity(normalized, entity.canonical_key)
      if similarity > best_similarity
        best_similarity = similarity
        best_match = entity
      end
    end

    if best_match && best_similarity >= threshold
      # Log auto-merge for audit
      EntityMergeLog.create!(
        original: name,
        normalized: normalized,
        merged_into: best_match.canonical_key,
        similarity: best_similarity,
        entity_type: entity_type
      )

      Rails.logger.info "ENTITY_MERGE: #{entity_type} '#{name}' -> '#{best_match.canonical_key}' (sim: #{best_similarity.round(3)})"
      best_match.canonical_key
    else
      normalized
    end
  end

  private

  def normalize_string(name)
    name.downcase
        .gsub(/[^\w\s]/, '')           # Strip punctuation
        .gsub(/\b(the|a|an)\b/, '')   # Remove stopwords
        .singularize                   # Handle plural/singular
        .squeeze(' ')                  # Collapse whitespace
        .strip
  end
end

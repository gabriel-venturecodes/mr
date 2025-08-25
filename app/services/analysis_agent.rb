require 'digest'

class AnalysisAgent
  def self.extract_from_chunks(chunks, prompt_version: "v1.0")
    new.extract_from_chunks(chunks, prompt_version: prompt_version)
  end

  def initialize
    @ai_client = AiClient.new
    @canonicalizer = EntityCanonicalizer.new
  end

  def extract_from_chunks(chunks, prompt_version: "v1.0")
    extracted_entities = []

    chunks.each do |chunk|
      begin
        entities_data = @ai_client.extract_entities(chunk, prompt_version: prompt_version)
        entities_data.each do |entity_data|
          entity = process_entity(entity_data, chunk, prompt_version)
          extracted_entities << entity if entity
        end
      rescue => e
        Rails.logger.error "Failed to extract entities from chunk #{chunk.id}: #{e.message}"
        next
      end
    end

    extracted_entities
  end

  # Relation extraction methods (merged from RelationExtractionService)
  def self.extract_relations_from_chunks(chunks, prompt_version: "v1.0")
    agent = new
    agent.extract_relations_from_chunks(chunks, prompt_version: prompt_version)
  end

  def extract_relations_from_chunks(chunks, prompt_version: "v1.0")
    extracted_relations = []

    chunks.each do |chunk|
      begin
        entities = get_entities_in_chunk(chunk)
        next if entities.empty?

        relations_data = @ai_client.extract_relations(chunk, entities, prompt_version: prompt_version)
        relations_data.each do |relation_data|
          relation = process_relation(relation_data, chunk, entities, prompt_version)
          extracted_relations << relation if relation
        end
      rescue => e
        Rails.logger.error "Failed to extract relations from chunk #{chunk.id}: #{e.message}"
        next
      end
    end

    extracted_relations
  end

  private

  def process_entity(entity_data, chunk, prompt_version)
    name = entity_data['name']
    entity_type = entity_data['type']

    # Canonicalize the entity name
    canonical_key = @canonicalizer.canonicalize(entity_type, name)

    # Find or create entity
    entity = Entity.find_or_create_by(
      entity_type: entity_type,
      canonical_key: canonical_key
    ) do |e|
      e.name = name
      e.prompt_version = prompt_version
      e.model_id = "gpt-4o-mini"
      e.input_hash = generate_input_hash(chunk, prompt_version)
      e.meta = {
        first_seen_chunk_id: chunk.id,
        extraction_confidence: 1.0
      }
    end

    # Update metadata if entity already exists
    if entity.persisted? && !entity.changed?
      update_entity_metadata(entity, chunk)
    end

    entity
  rescue => e
    Rails.logger.error "Failed to process entity '#{name}' (#{entity_type}): #{e.message}"
    nil
  end

  def update_entity_metadata(entity, chunk)
    meta = entity.meta || {}
    meta['seen_in_chunks'] = (meta['seen_in_chunks'] || []) + [chunk.id]
    meta['occurrence_count'] = (meta['occurrence_count'] || 0) + 1
    meta['last_seen_at'] = Time.current

    entity.update(meta: meta)
  end

  def generate_input_hash(chunk, prompt_version)
    content = "#{chunk.text}-#{prompt_version}-entities"
    Digest::SHA256.hexdigest(content)
  end

  def get_entities_in_chunk(chunk)
    # Get entities that appear in this chunk's document
    Entity.joins("JOIN chunks ON chunks.document_id = entities.meta->>'first_seen_chunk_id'::integer")
          .where("chunks.document_id = ?", chunk.document_id)
          .distinct
  end

  def process_relation(relation_data, chunk, entities, prompt_version)
    src_name = relation_data['src']
    dst_name = relation_data['dst']
    relation_type = relation_data['type']
    confidence = relation_data['confidence']&.to_f || 0.5

    # Find matching entities
    src_entity = find_entity_by_name(entities, src_name)
    dst_entity = find_entity_by_name(entities, dst_name)

    return nil unless src_entity && dst_entity

    # Create or find relation
    relation = Relation.find_or_create_by(
      src_entity: src_entity,
      dst_entity: dst_entity,
      relation_type: relation_type
    ) do |r|
      r.confidence = confidence
      r.prompt_version = prompt_version
      r.model_id = "gpt-4o-mini"
      r.input_hash = generate_relation_input_hash(chunk, src_name, dst_name, prompt_version)
      r.meta = {
        first_seen_chunk_id: chunk.id,
        extraction_confidence: confidence
      }
    end

    relation
  rescue => e
    Rails.logger.error "Failed to process relation '#{src_name}' -> '#{dst_name}': #{e.message}"
    nil
  end

  def find_entity_by_name(entities, name)
    entities.find { |entity| entity.name.downcase.strip == name.downcase.strip }
  end

  def generate_relation_input_hash(chunk, src_name, dst_name, prompt_version)
    content = "#{chunk.text}-#{src_name}-#{dst_name}-#{prompt_version}-relations"
    Digest::SHA256.hexdigest(content)
  end

  private
end

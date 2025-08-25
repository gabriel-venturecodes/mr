# Golden Dataset for NDL Platform Demo
# This creates a curated set of documents, entities, and relations
# that guarantee interesting demo results

class GoldenDatasetSeeder
  def self.seed!
    new.seed!
  end

  def seed!
    Rails.logger.info "Seeding golden dataset for NDL Platform demo..."

    # Clear existing data
    clear_existing_data

    # Create demo documents
    create_demo_documents

    # Create demo entities
    create_demo_entities

    # Create demo relations
    create_demo_relations

    # Create entity aliases for canonicalization
    create_entity_aliases

    Rails.logger.info "Golden dataset seeded successfully!"
  end

  private

  def clear_existing_data
    Claim.destroy_all
    Hypothesis.destroy_all
    Relation.destroy_all
    Entity.destroy_all
    Chunk.destroy_all
    Document.destroy_all
    EntityAlias.destroy_all
    EntityMergeLog.destroy_all
  end

  def create_demo_documents
    # Document 1: Customer Survey Data
    doc1 = Document.create!(
      title: "Customer Survey Q3 2024.csv",
      source_uri: "customer_survey_q3_2024.csv",
      mime_type: "text/csv",
      processing_status: "completed",
      meta: {
        extracted_text: customer_survey_text,
        file_size: 15_420,
        upload_timestamp: 2.days.ago
      }
    )

    # Document 2: Product Review Analysis
    doc2 = Document.create!(
      title: "EcoMilk Product Reviews.json",
      source_uri: "ecomilk_reviews.json",
      mime_type: "application/json",
      processing_status: "completed",
      meta: {
        extracted_text: product_review_text,
        file_size: 8_930,
        upload_timestamp: 1.day.ago
      }
    )

    # Document 3: Market Research Report
    doc3 = Document.create!(
      title: "Gen Z Coffee Consumption Report.pdf",
      source_uri: "genz_coffee_report.pdf",
      mime_type: "application/pdf",
      processing_status: "completed",
      meta: {
        extracted_text: market_report_text,
        file_size: 245_120,
        upload_timestamp: 3.hours.ago
      }
    )

    # Create chunks for each document
    create_chunks_for_document(doc1, customer_survey_chunks)
    create_chunks_for_document(doc2, product_review_chunks)
    create_chunks_for_document(doc3, market_report_chunks)
  end

  def create_chunks_for_document(document, chunk_texts)
    chunk_texts.each_with_index do |text, index|
      document.chunks.create!(
        text: text,
        position: index,
        chunk_hash: Digest::SHA256.hexdigest("#{document.id}-#{text}-#{index}"),
        meta: {
          token_count: (text.split.count / 0.75).ceil,
          word_count: text.split.count
        }
      )
    end
  end

  def create_demo_entities
    entities_data = [
      { type: "Demographic", name: "Gen Z", canonical_key: "gen z" },
      { type: "Demographic", name: "Millennials", canonical_key: "millennials" },
      { type: "Demographic", name: "18-25 age group", canonical_key: "18-25 age group" },
      { type: "Product", name: "EcoMilk Oat Milk", canonical_key: "ecomilk oat milk" },
      { type: "Product", name: "Coffee", canonical_key: "coffee" },
      { type: "Attribute", name: "Eco-friendly packaging", canonical_key: "eco-friendly packaging" },
      { type: "Attribute", name: "Taste", canonical_key: "taste" },
      { type: "Attribute", name: "Price", canonical_key: "price" },
      { type: "Company", name: "Starbucks", canonical_key: "starbucks" },
      { type: "Metric", name: "Purchase Intent", canonical_key: "purchase intent" },
      { type: "Campaign", name: "Sustainability Initiative", canonical_key: "sustainability initiative" }
    ]

    entities_data.each do |data|
      Entity.create!(
        name: data[:name],
        entity_type: data[:type],
        canonical_key: data[:canonical_key],
        prompt_version: "demo_v1.0",
        model_id: "demo-seeded",
        input_hash: Digest::SHA256.hexdigest("demo-#{data[:name]}"),
        meta: {
          demo_entity: true,
          created_for_demo: true
        }
      )
    end
  end

  def create_demo_relations
    # Create meaningful relations between entities
    relations_data = [
      {
        src: "gen z", dst: "eco-friendly packaging", type: "rated_highly_by", confidence: 0.85,
        chunk_text: "Gen Z consumers consistently rate eco-friendly packaging as a top priority"
      },
      {
        src: "18-25 age group", dst: "taste", type: "criticized_for", confidence: 0.72,
        chunk_text: "The 18-25 age group frequently criticized the taste when used in coffee"
      },
      {
        src: "ecomilk oat milk", dst: "price", type: "criticized_for", confidence: 0.68,
        chunk_text: "EcoMilk oat milk received criticism for its premium pricing"
      },
      {
        src: "millennials", dst: "sustainability initiative", type: "correlates_with", confidence: 0.91,
        chunk_text: "Millennial preferences strongly correlate with sustainability initiatives"
      },
      {
        src: "eco-friendly packaging", dst: "purchase intent", type: "increases", confidence: 0.79,
        chunk_text: "Eco-friendly packaging significantly increases purchase intent among target demographics"
      }
    ]

    relations_data.each do |data|
      src_entity = Entity.find_by(canonical_key: data[:src])
      dst_entity = Entity.find_by(canonical_key: data[:dst])

      next unless src_entity && dst_entity

      # Find a chunk that contains related text or use any available chunk
      chunk = Chunk.joins(:document).where("chunks.text ILIKE ?", "%#{data[:chunk_text].split.first(2).join('%')}%").first

      # If no matching chunk found, use the first chunk
      chunk ||= Chunk.first

      # Skip this relation if no chunks exist at all
      next unless chunk

      chunk_ids = [chunk.id]

      Relation.create!(
        src_entity: src_entity,
        dst_entity: dst_entity,
        relation_type: data[:type],
        confidence: data[:confidence],
        source_chunk_ids: chunk_ids,
        prompt_version: "demo_v1.0",
        model_id: "demo-seeded",
        input_hash: Digest::SHA256.hexdigest("demo-relation-#{src_entity.id}-#{dst_entity.id}"),
        meta: {
          demo_relation: true,
          expected_in_demo: true
        }
      )
    end
  end

  def create_entity_aliases
    aliases_data = [
      { type: "Demographic", variant: "generation z", canonical: "gen z" },
      { type: "Demographic", variant: "genz", canonical: "gen z" },
      { type: "Demographic", variant: "young adults", canonical: "18-25 age group" },
      { type: "Product", variant: "oat milk", canonical: "ecomilk oat milk" },
      { type: "Attribute", variant: "sustainable packaging", canonical: "eco-friendly packaging" },
      { type: "Attribute", variant: "flavor", canonical: "taste" }
    ]

    aliases_data.each do |data|
      EntityAlias.create!(
        entity_type: data[:type],
        variant: data[:variant],
        canonical_name: data[:canonical]
      )
    end
  end

  # Sample text content for demo documents
  def customer_survey_text
    <<~TEXT
      Customer satisfaction survey results from Q3 2024 showing consumer preferences across demographics.

      Gen Z respondents (ages 18-25) showed strong preference for eco-friendly packaging, rating it 4.2/5 on average.
      Millennials demonstrated high correlation with sustainability initiatives, with 87% indicating it influences purchase decisions.

      Product taste ratings varied significantly by age group, with younger consumers more critical of traditional flavors.
      The 18-25 demographic particularly criticized taste when EcoMilk oat milk was used in coffee preparations.

      Price sensitivity analysis revealed premium pricing concerns, especially for EcoMilk oat milk products.
      Purchase intent increased by 65% when eco-friendly packaging was prominently featured in marketing materials.
    TEXT
  end

  def product_review_text
    <<~TEXT
      Comprehensive analysis of EcoMilk oat milk product reviews from multiple platforms.

      Positive feedback consistently highlighted the eco-friendly packaging design and sustainability messaging.
      Starbucks partnership reviews showed mixed results, with packaging praised but taste in coffee receiving lower scores.

      Review sentiment analysis indicates strong correlation between environmental values and positive ratings.
      Gen Z reviewers specifically mentioned sustainability as a key purchase driver.

      Negative reviews primarily focused on taste profile when mixed with coffee and premium pricing concerns.
      The sustainability initiative marketing campaign resonated well with target demographics.
    TEXT
  end

  def market_report_text
    <<~TEXT
      Market research report on Gen Z coffee consumption patterns and alternative milk preferences.

      Key findings indicate shift toward plant-based alternatives, with oat milk leading category growth.
      Gen Z consumers prioritize environmental impact, rating eco-friendly packaging as top purchase criterion.

      Taste preferences show evolution from traditional dairy, though coffee compatibility remains important.
      Price elasticity analysis suggests premium positioning viable for environmentally-conscious segments.

      Millennial and Gen Z demographics show highest alignment with sustainability initiatives.
      Purchase intent modeling demonstrates strong correlation between environmental messaging and conversion rates.
    TEXT
  end

  def customer_survey_chunks
    [
      "Customer satisfaction survey results from Q3 2024 showing consumer preferences across demographics. Gen Z respondents (ages 18-25) showed strong preference for eco-friendly packaging, rating it 4.2/5 on average.",
      "Millennials demonstrated high correlation with sustainability initiatives, with 87% indicating it influences purchase decisions. Product taste ratings varied significantly by age group, with younger consumers more critical of traditional flavors.",
      "The 18-25 demographic particularly criticized taste when EcoMilk oat milk was used in coffee preparations. Price sensitivity analysis revealed premium pricing concerns, especially for EcoMilk oat milk products.",
      "Purchase intent increased by 65% when eco-friendly packaging was prominently featured in marketing materials. This correlation was strongest among Gen Z and Millennial segments."
    ]
  end

  def product_review_chunks
    [
      "Comprehensive analysis of EcoMilk oat milk product reviews from multiple platforms. Positive feedback consistently highlighted the eco-friendly packaging design and sustainability messaging.",
      "Starbucks partnership reviews showed mixed results, with packaging praised but taste in coffee receiving lower scores. Review sentiment analysis indicates strong correlation between environmental values and positive ratings.",
      "Gen Z reviewers specifically mentioned sustainability as a key purchase driver. Negative reviews primarily focused on taste profile when mixed with coffee and premium pricing concerns.",
      "The sustainability initiative marketing campaign resonated well with target demographics, particularly among environmentally-conscious consumers."
    ]
  end

  def market_report_chunks
    [
      "Market research report on Gen Z coffee consumption patterns and alternative milk preferences. Key findings indicate shift toward plant-based alternatives, with oat milk leading category growth.",
      "Gen Z consumers prioritize environmental impact, rating eco-friendly packaging as top purchase criterion. Taste preferences show evolution from traditional dairy, though coffee compatibility remains important.",
      "Price elasticity analysis suggests premium positioning viable for environmentally-conscious segments. Millennial and Gen Z demographics show highest alignment with sustainability initiatives.",
      "Purchase intent modeling demonstrates strong correlation between environmental messaging and conversion rates. Environmental packaging features drive 65% increase in purchase consideration."
    ]
  end
end

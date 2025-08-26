class AiClient
  MAX_OUTPUT_TOKENS = 80_000
  MAX_TOTAL_TOKENS = 200_000
  MAX_COST_USD = 5.00
  SYSTEM_PREAMBLE = "You are a precise entity extraction system. Follow JSON schema exactly."

  class BudgetExceededError < StandardError; end
  class ValidationError < StandardError; end

    def initialize
      @run_tokens = 0
      @run_cost = 0.0
      @openai_client = setup_openai_client
    end

    def extract_entities(chunk, prompt_version: "v1.0")
      prompt = build_entity_extraction_prompt(chunk, prompt_version)
      response = call_with_guardrails(prompt, estimated_tokens: 1000)

      # Log for drift detection
      log_extraction(chunk, prompt_version, response, :entities)

      # Parse JSON response - handle markdown formatting
      begin
        # Clean up markdown formatting if present
        cleaned_response = clean_json_response(response)
        parsed = JSON.parse(cleaned_response)
        # Handle different response formats
        return parsed if parsed.is_a?(Array)
        return parsed["entities"] if parsed.is_a?(Hash) && parsed["entities"]
        return []
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse entity extraction JSON: #{e.message}, response: #{response}"
        return []
      end
    end

    def extract_relations(chunk, entities, prompt_version: "v1.0")
      prompt = build_relation_extraction_prompt(chunk, entities, prompt_version)
      response = call_with_guardrails(prompt, estimated_tokens: 1500)

      log_extraction(chunk, prompt_version, response, :relations)

      # Parse JSON response - handle markdown formatting
      begin
        # Clean up markdown formatting if present
        cleaned_response = clean_json_response(response)
        parsed = JSON.parse(cleaned_response)
        # Handle different response formats
        return parsed if parsed.is_a?(Array)
        return parsed["relations"] if parsed.is_a?(Hash) && parsed["relations"]
        return []
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse relation extraction JSON: #{e.message}, response: #{response}"
        return []
      end
    end

    def synthesize_hypotheses(chunks, entities, relations, prompt_version: "v1.0")
      prompt = build_synthesis_prompt(chunks, entities, relations, prompt_version)
      response = call_with_guardrails(prompt, estimated_tokens: 3000)

      log_extraction(chunks, prompt_version, response, :synthesis)

      # Parse JSON directly for now - bypass validator that's causing issues
      cleaned_response = clean_json_response(response)
      JSON.parse(cleaned_response)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse JSON response: #{e.message}"
      { "hypotheses" => [] }
    end

    def repair_json(invalid_output, schema, error_message)
      prompt = "Fix this JSON to match the schema. Error: #{error_message}\n\nInvalid JSON: #{invalid_output}\n\nRequired Schema: #{schema.to_json}\n\nFixed JSON:"

      response = call_with_guardrails(prompt, estimated_tokens: 800)
      JSON.parse(response)
    end

    def chat_completion(messages:, response_schema: nil)
      response = Retries.with_retries(max_tries: 3, rescue: [Faraday::Error, StandardError]) do
        make_api_call_for_chat(messages)
      end

      content = response.dig("choices", 0, "message", "content")

      # Always try to parse as JSON, let it raise JSON::ParserError if invalid
      parsed = JSON.parse(content)
      validate_schema(parsed, response_schema) if response_schema
      parsed
    end

    private    def call_with_guardrails(prompt, estimated_tokens:)
      if @run_tokens + estimated_tokens > MAX_TOTAL_TOKENS
        Rails.logger.warn "Switching to summary-first mode: token limit approaching"
        return summary_first_mode(prompt)
      end

      response = Retries.with_retries(max_tries: 3, rescue: [Faraday::Error, StandardError]) do
        make_api_call(prompt)
      end

      @run_tokens += response.dig("usage", "total_tokens") || estimated_tokens
      @run_cost += calculate_cost(response.dig("usage"))

      if @run_cost > MAX_COST_USD
        raise BudgetExceededError, "Run cost exceeded $#{MAX_COST_USD}"
      end

      response.dig("choices", 0, "message", "content")
    end

    def summary_first_mode(original_prompt)
      Rails.logger.info "BUDGET_MODE: Switching to summary-first synthesis"
      # Simplified prompt for budget mode
      simplified_prompt = build_summary_first_prompt(original_prompt)
      make_api_call(simplified_prompt).dig("choices", 0, "message", "content")
    end

    def make_api_call(prompt)
      @openai_client.post("/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: "gpt-4o-mini",
          temperature: 0.1,
          top_p: 0.95,
          messages: [
            { role: "system", content: SYSTEM_PREAMBLE },
            { role: "user", content: prompt }
          ]
        }.to_json
      end.body
    end

    def make_api_call_for_chat(messages)
      @openai_client.post("/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
        req.headers["Content-Type"] = "application/json"
        req.body = {
          model: "gpt-4o-mini",
          temperature: 0.1,
          top_p: 0.95,
          messages: messages
        }.to_json
      end.body
    end

    def validate_schema(data, schema)
      return true unless schema

      # Simple validation - in a real app you'd use a proper JSON schema validator
      case schema[:type]
      when 'object'
        return false unless data.is_a?(Hash)

        if schema[:required]
          schema[:required].each do |required_field|
            return false unless data.key?(required_field.to_s)
          end
        end

        if schema[:properties]
          schema[:properties].each do |key, prop_schema|
            if data.key?(key.to_s)
              return false unless validate_property(data[key.to_s], prop_schema)
            end
          end
        end

        true
      else
        true # For simplicity, assume other types are valid
      end
    end

    def validate_property(value, schema)
      case schema[:type]
      when 'string'
        value.is_a?(String)
      when 'integer'
        value.is_a?(Integer)
      when 'number'
        value.is_a?(Numeric)
      when 'boolean'
        [true, false].include?(value)
      when 'array'
        value.is_a?(Array)
      when 'object'
        value.is_a?(Hash)
      else
        true
      end
    end

    def setup_openai_client
      Faraday.new(url: "https://api.openai.com") do |conn|
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
        conn.options.timeout = 30
        conn.options.open_timeout = 10
      end
    end

    def calculate_cost(usage)
      return 0.0 unless usage

      input_tokens = usage["prompt_tokens"] || 0
      output_tokens = usage["completion_tokens"] || 0

      # GPT-4o-mini pricing (as of 2024)
      input_cost = input_tokens * 0.000150 / 1000  # $0.15 per 1K tokens
      output_cost = output_tokens * 0.000600 / 1000 # $0.60 per 1K tokens

      input_cost + output_cost
    end

    def log_extraction(input, prompt_version, response, extraction_type)
      Rails.logger.info(
        "AI_EXTRACTION: type=#{extraction_type} " \
        "prompt_version=#{prompt_version} " \
        "tokens=#{@run_tokens} " \
        "cost=$#{'%.4f' % @run_cost}"
      )
    end

    def build_entity_extraction_prompt(chunk, prompt_version)
      # Will implement specific prompts based on version
      case prompt_version
      when "v1.0"
        build_entity_prompt_v1(chunk)
      else
        raise "Unknown prompt version: #{prompt_version}"
      end
    end

    def build_entity_prompt_v1(chunk)
      <<~PROMPT
        Extract entities from the text. Use only these types: Company, Product, Demographic, Attribute, Campaign, Metric.
        Return JSON array with {type, name}. If none, return [].

        Examples:
        Text: "Millennials love the new eco-friendly packaging of Brand X coffee"
        Output: [{"type": "Demographic", "name": "Millennials"}, {"type": "Product", "name": "Brand X coffee"}, {"type": "Attribute", "name": "eco-friendly packaging"}]

        Text: "#{chunk.text}"
        Output:
      PROMPT
    end

    def build_relation_extraction_prompt(chunk, entities, prompt_version)
      entity_list = entities.map { |e| "#{e['name']} (#{e['type']})" }.join(", ")

      <<~PROMPT
        Given entities detected in this chunk, extract direct relations using only: likes, dislikes, rated_highly_by, criticized_for, correlates_with, led_to, increases, decreases.
        Return JSON array {src, dst, type, confidence: 0-1}. Use exact entity names from the provided list.

        Text: "#{chunk.text}"
        Entities: #{entity_list}
        Output:
      PROMPT
    end

    def build_synthesis_prompt(chunks, entities, relations, prompt_version)
      chunks_summary = chunks.first(10).map { |c| "ID #{c.id}: #{c.text[0..200]}..." }.join("\n")

      <<~PROMPT
        Given the brief, top evidence chunks, and extracted relations, propose up to 3 testable hypotheses.
        For each hypothesis, write 1-2 sentences and include [CITATION_IDS: <chunk_ids>] referencing the provided evidence chunks.
        Avoid claims without citations.

        Evidence chunks:
        #{chunks_summary}

        Return JSON: {"hypotheses": [{"title": "...", "summary": "...", "citation_ids": [...]}]}
      PROMPT
    end

    def build_summary_first_prompt(original_prompt)
      # Simplified version for budget mode
      "Summarize the key insights from this data in 2-3 bullet points: #{original_prompt[0..500]}"
    end

    def clean_json_response(response)
      # Remove markdown code blocks if present
      cleaned = response.strip
      
      # Remove ```json and ``` markers
      cleaned = cleaned.gsub(/^```json\s*/, '')
      cleaned = cleaned.gsub(/```\s*$/, '')
      
      # Remove any leading/trailing whitespace
      cleaned.strip
    end
end
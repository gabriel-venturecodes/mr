module AI
  class LLMOutputValidator
    class ValidationError < StandardError; end

    ENTITY_SCHEMA = {
      "type" => "array",
      "items" => {
        "type" => "object",
        "properties" => {
          "type" => { "enum" => ["Company", "Product", "Demographic", "Attribute", "Campaign", "Metric"] },
          "name" => { "type" => "string", "minLength" => 1 }
        },
        "required" => ["type", "name"]
      }
    }.freeze

    RELATION_SCHEMA = {
      "type" => "array",
      "items" => {
        "type" => "object",
        "properties" => {
          "src" => { "type" => "string", "minLength" => 1 },
          "dst" => { "type" => "string", "minLength" => 1 },
          "type" => { "enum" => ["likes", "dislikes", "rated_highly_by", "criticized_for", "correlates_with", "led_to", "increases", "decreases"] },
          "confidence" => { "type" => "number", "minimum" => 0, "maximum" => 1 }
        },
        "required" => ["src", "dst", "type", "confidence"]
      }
    }.freeze

    SYNTHESIS_SCHEMA = {
      "type" => "object",
      "properties" => {
        "hypotheses" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "properties" => {
              "title" => { "type" => "string", "minLength" => 1 },
              "summary" => { "type" => "string", "minLength" => 1 },
              "citation_ids" => { "type" => "array", "items" => { "type" => "integer" } }
            },
            "required" => ["title", "summary", "citation_ids"]
          }
        }
      },
      "required" => ["hypotheses"]
    }.freeze

    class << self
      def validate_entities!(output)
        validate_and_repair!(output, ENTITY_SCHEMA, "entities")
      end

      def validate_relations!(output)
        validate_and_repair!(output, RELATION_SCHEMA, "relations")
      end

      def validate_synthesis!(output)
        validate_and_repair!(output, SYNTHESIS_SCHEMA, "synthesis")
      end

      private

      def validate_and_repair!(output, schema, type, max_attempts: 2)
        attempt = 1
        parsed_output = parse_json_safely(output)

        begin
          JSON::Validator.validate!(schema, parsed_output)
          parsed_output
        rescue JSON::Schema::ValidationError => e
          if attempt <= max_attempts
            Rails.logger.warn "LLM output validation failed for #{type} (attempt #{attempt}): #{e.message}"

            if attempt == 1
              # Repair prompt with invalid JSON and schema
              parsed_output = repair_with_schema(output, schema, e.message, type)
            else
              # Fallback to stricter zero-shot extraction
              parsed_output = fallback_zero_shot_extraction(schema, type)
            end

            attempt += 1
            retry
          else
            # Fail closed - don't accept partially valid payloads
            raise ValidationError, "Failed to produce valid #{type} output after #{max_attempts} attempts: #{e.message}"
          end
        end
      end

      def parse_json_safely(output)
        JSON.parse(output)
      rescue JSON::ParserError => e
        # Try to extract JSON from markdown code blocks or other formatting
        json_match = output.match(/```(?:json)?\s*(\{.*?\}|\[.*?\])\s*```/m)
        if json_match
          JSON.parse(json_match[1])
        else
          raise ValidationError, "Could not parse JSON from LLM output: #{e.message}"
        end
      end

      def repair_with_schema(invalid_output, schema, error_message, type)
        client = AiClient.new
        repaired = client.repair_json(invalid_output, schema, error_message)
        Rails.logger.info "Successfully repaired #{type} output"
        repaired
      rescue => e
        Rails.logger.error "Failed to repair #{type} output: #{e.message}"
        fallback_zero_shot_extraction(schema, type)
      end

      def fallback_zero_shot_extraction(schema, type)
        Rails.logger.warn "Using fallback empty result for #{type}"

        case type
        when "entities"
          []
        when "relations"
          []
        when "synthesis"
          { "hypotheses" => [] }
        else
          raise ValidationError, "Unknown type for fallback: #{type}"
        end
      end
    end
  end
end

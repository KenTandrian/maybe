require "google/cloud/ai_platform/v1"
require "ostruct"

class Provider::Gemini < Provider
  include LlmConcept

  # Subclass so errors caught in this provider are raised as Provider::Gemini::Error
  Error = Class.new(Provider::Error)

  MODELS = %w[gemini-2.0-flash-lite-001]

  def initialize(project_id:, location: "us-central1")
    @client = Google::Cloud::AIPlatform::V1::PredictionService::Client.new
    @project_id = project_id
    @location = location
  end

  def supports_model?(model)
    MODELS.include?(model)
  end

  def chat_response(prompt, model:, instructions: nil, functions: [], function_results: [], streamer: nil, previous_response_id: nil)
    with_provider_response do
      endpoint = "projects/#{@project_id}/locations/#{@location}/publishers/google/models/#{model}"

      part = Google::Cloud::AIPlatform::V1::Part.new(
        text: prompt
      )
      content = Google::Cloud::AIPlatform::V1::Content.new(
        parts: [ part ],
        role: "user"
      )

      request = Google::Cloud::AIPlatform::V1::GenerateContentRequest.new(
        model: endpoint,
        contents: [ content ]
      )

      collected_chunks = []

      if streamer.present?
        # Iterate over the lazy enumerator to process streaming responses
        @client.stream_generate_content(request).each do |response|
          Rails.logger.debug("Raw streaming response: #{response.inspect}")
          parsed_chunk = parse_streaming_chunk(response)

          unless parsed_chunk.nil?
            streamer.call(parsed_chunk)
            collected_chunks << parsed_chunk
          end
        end

        # Return the "response chunk" from the collected chunks
        response_chunk = collected_chunks.find { |chunk| chunk.type == "response" }
        response_chunk&.data
      else
        # Handle non-streaming responses
        response = @client.generate_content(request)
        parse_response(response)
      end
    end
  end

  private

    def parse_streaming_chunk(chunk)
      if chunk.respond_to?(:candidates) && chunk.candidates.present?
        first_candidate = chunk.candidates.first

        if first_candidate.content.parts.present?
          # Return a structured object with a `type` and `data`
          OpenStruct.new(
            type: "output_text",
            data: first_candidate.content.parts.first.text
          )
        else
          nil
        end
      else
        nil
      end
    end

    def parse_response(response)
      if response.candidates.present? && response.candidates.first.content.parts.present?
        response.candidates.first.content.parts.first.text
      else
        Rails.logger.warn("Unexpected response format: #{response.inspect}")
        nil
      end
    end
end

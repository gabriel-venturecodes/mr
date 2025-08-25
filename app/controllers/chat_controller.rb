class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    @documents = Document.all.order(created_at: :desc)
    @recent_hypotheses = Hypothesis.verified.limit(5).order(created_at: :desc)
  end

  # def analyze
  #   @brief = params[:brief]
  #   uploaded_files = params[:documents]&.reject(&:blank?) || []

  #   if @brief.blank?
  #     redirect_to root_path, alert: "Please enter a research brief"
  #     return
  #   end

  #   begin
  #     # Start async job and get job ID
  #     if uploaded_files.any?
  #       Rails.logger.info "Processing #{uploaded_files.count} uploaded files with analysis"

  #       # Store uploaded files temporarily
  #       file_paths = uploaded_files.map do |file|
  #         temp_path = Rails.root.join('tmp', 'uploads', "#{SecureRandom.uuid}_#{file.original_filename}")
  #         FileUtils.mkdir_p(File.dirname(temp_path))
  #         File.open(temp_path, 'wb') { |f| f.write(file.read) }
  #         temp_path.to_s
  #       end

  #       job = AnalysisJob.perform_later(current_user.id, @brief, file_paths)
  #     else
  #       job = AnalysisJob.perform_later(current_user.id, @brief)
  #     end

  #     respond_to do |format|
  #       format.html { render :loading, locals: { jid: job.jid, brief: @brief } }
  #       format.turbo_stream {
  #         render turbo_stream: turbo_stream.replace("chat-messages",
  #           partial: "chat/analysis_loading",
  #           locals: { brief: @brief, jid: job.jid }
  #         )
  #       }
  #     end
  #   rescue => e
  #     Rails.logger.error "Failed to start analysis: #{e.message}"

  #     respond_to do |format|
  #       format.html { redirect_to root_path, alert: "Failed to start analysis: #{e.message}" }
  #       format.turbo_stream {
  #         render turbo_stream: turbo_stream.replace("chat-messages",
  #           partial: "chat/error",
  #           locals: { error: e.message }
  #         )
  #       }
  #     end
  #   end
  # end

  def analyze
    brief = params[:brief]
    uploaded_files = params[:documents]&.reject(&:blank?) || []

    if brief.blank?
      redirect_to root_path, alert: "Please enter a research brief"
      return
    end

    begin
      # Store uploaded files temporarily and create file objects
      uploaded_file_objects = uploaded_files.map do |file|
        temp_path = Rails.root.join('tmp', 'uploads', "#{SecureRandom.uuid}_#{file.original_filename}")
        FileUtils.mkdir_p(File.dirname(temp_path))
        File.open(temp_path, 'wb') { |f| f.write(file.read) }
        
        # Create a file object that mimics the uploaded file
        File.open(temp_path, 'rb').tap do |file_obj|
          filename = File.basename(temp_path)
          content_type = case File.extname(filename).downcase
                         when '.pdf' then 'application/pdf'
                         when '.csv' then 'text/csv'
                         when '.json' then 'application/json'
                         when '.txt' then 'text/plain'
                         else 'application/octet-stream'
                         end

          file_obj.define_singleton_method(:original_filename) { file.original_filename }
          file_obj.define_singleton_method(:content_type) { content_type }
          file_obj.define_singleton_method(:size) { File.size(temp_path) }
        end
      end

      # Run analysis synchronously using OrchestratorAgent
      if uploaded_file_objects.any?
        result = OrchestratorAgent.new.analyze_with_new_documents(brief, uploaded_file_objects)
      else
        result = OrchestratorAgent.new.analyze(brief)
      end

      # Clean up temporary files
      uploaded_file_objects.each(&:close) if uploaded_file_objects
      
      if result[:success]
        # Create analysis record
        analysis = current_user.analyses.create!(
          brief: brief,
          status: 'completed',
          progress: 100,
          status_message: 'Analysis complete!',
          hypotheses: result[:hypotheses],
          completed_at: Time.current
        )

        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace("chat-messages",
              partial: "chat/analysis_results",
              locals: { 
                hypotheses: result[:hypotheses],
                analysis: analysis,
                brief: brief
              }
            )
          }
        end
      else
        raise StandardError, result[:error]
      end

    rescue => e
      Rails.logger.error "Analysis failed: #{e.message}"
      
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("chat-messages",
            partial: "chat/error",
            locals: { error: e.message }
          )
        }
      end
    end
  end



  def select_insight
    hypothesis_id = params[:hypothesis_id]
    hypothesis = Hypothesis.find(hypothesis_id)

    # Create or find conversation
    conversation = current_user.current_conversation
    if conversation.nil?
      conversation = current_user.start_new_conversation("Research: #{hypothesis.title[0..50]}...")
    end

    # Mark this insight as selected
    message = conversation.conversation_messages.create!(
      message_type: 'insight_selection',
      content: {
        hypothesis_id: hypothesis.id,
        hypothesis_title: hypothesis.title,
        hypothesis_summary: hypothesis.summary
      },
      metadata: {
        selected_at: Time.current,
        selected: true
      }
    )

    # Set as current insight in conversation
    conversation.set_current_insight(hypothesis.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("chat-messages",
          partial: "chat/conversation_interface",
          locals: {
            hypothesis: hypothesis,
            conversation: conversation
          }
        )
      end
      format.html do
        render partial: 'chat/conversation_interface',
               locals: {
                 hypothesis: hypothesis,
                 conversation: conversation
               }
      end
      format.json do
        render json: {
          status: 'success',
          conversation_id: conversation.id,
          hypothesis_id: hypothesis.id
        }
      end
    end
  end

  def continue_conversation
    message_content = params[:message]
    conversation = current_user.current_conversation

    if message_content.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash_message",
            locals: { message: "Message cannot be blank", type: "error" }
          )
        end
        format.json { render json: { error: "Message cannot be blank" }, status: 400 }
      end
      return
    end

    if conversation.nil?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash_message",
            locals: { message: "No active conversation found", type: "error" }
          )
        end
        format.json { render json: { error: "No active conversation found" }, status: 404 }
      end
      return
    end

    # Add user message
    user_message = conversation.conversation_messages.create!(
      message_type: 'user',
      content: { text: message_content },
      metadata: { timestamp: Time.current }
    )

    # Generate AI response
    ai_response = generate_ai_response(message_content, conversation)

    ai_message = conversation.conversation_messages.create!(
      message_type: 'assistant',
      content: { text: ai_response },
      metadata: { timestamp: Time.current }
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("conversation-messages",
            partial: "chat/conversation_message",
            locals: { message: user_message, sender: 'user' }
          ),
          turbo_stream.append("conversation-messages",
            partial: "chat/conversation_message",
            locals: { message: ai_message, sender: 'assistant' }
          )
        ]
      end
      format.json do
        render json: {
          user_message: {
            id: user_message.id,
            content: user_message.content,
            created_at: user_message.created_at
          },
          ai_message: {
            id: ai_message.id,
            content: ai_message.content,
            created_at: ai_message.created_at
          }
        }
      end
    end
  end

  def conversation_suggestions
    conversation = current_user.current_conversation

    if conversation.nil?
      render json: { suggestions: [] }
      return
    end

    current_insight = conversation.current_insight_id ? Hypothesis.find(conversation.current_insight_id) : nil

    suggestions = if current_insight
      [
        "Tell me more about the evidence supporting this insight",
        "What are the limitations or potential biases in this analysis?",
        "How does this insight compare to industry benchmarks?",
        "What actions should we take based on this insight?",
        "Show me the original source quotes for this insight"
      ]
    else
      [
        "Can you analyze additional documents?",
        "What other research questions should we explore?",
        "How confident are you in these findings?",
        "What gaps exist in the current analysis?"
      ]
    end

    render json: { suggestions: suggestions }
  end

  private

  def perform_analysis(brief, uploaded_files = [])
    # Use the full analysis orchestrator
    if uploaded_files.any?
      Rails.logger.info "Processing #{uploaded_files.count} uploaded files with analysis"
      result = OrchestratorAgent.new.analyze_with_new_documents(brief, uploaded_files)
    else
      Rails.logger.info "Analyzing existing documents only"
      result = OrchestratorAgent.analyze(brief)
    end

    if result[:success]
      {
        hypotheses: result[:hypotheses],
        message: "Analysis complete! Generated #{result[:hypotheses].count} hypotheses from #{result.dig(:stats, :documents_analyzed)} documents.",
        stats: result[:stats]
      }
    else
      {
        hypotheses: [],
        message: result[:error] || "Analysis failed",
        error: true
      }
    end
  end

  def generate_ai_response(user_message, conversation)
    # This is a simplified response generator
    # In a real implementation, this would use the AI agents to generate contextual responses

    current_insight = conversation.current_insight_id ? Hypothesis.find(conversation.current_insight_id) : nil

    if current_insight
      case user_message.downcase
      when /evidence|support/
        "Based on the analysis, this insight is supported by #{current_insight.claims.verified.count} verified claims from your documents. The evidence shows #{current_insight.summary}"
      when /limitation|bias/
        "Some potential limitations to consider: The analysis is based on the specific documents provided, and the confidence level is #{current_insight.confidence}%. Additional data sources might provide different perspectives."
      when /action|recommend/
        "Based on this insight, I recommend: 1) Validate findings with additional sources, 2) Develop implementation strategies, 3) Monitor key metrics mentioned in the analysis."
      else
        "That's an interesting question about '#{current_insight.title}'. The analysis shows #{current_insight.summary}. Would you like me to dive deeper into any specific aspect?"
      end
    else
      "I'd be happy to help you explore that further. Could you be more specific about what aspect you'd like to investigate?"
    end
  end
end

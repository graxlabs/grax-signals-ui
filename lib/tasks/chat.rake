require 'readline'

namespace :chat do
  desc "Interactive chat with AI assistant for Salesforce data analysis"
  task datalake: :environment do
    Rails.logger.level = Logger::WARN
    Langchain.logger.level = Logger::WARN
    ChatCLI.new.start
  end
end

class ChatCLI
  def initialize
    @llm = Langchain::LLM::Anthropic.new(
      api_key: ENV["ANTHROPIC_API_KEY"],
      default_options: { max_tokens: 5_000 },
    )
    @tool = AthenaQueryTool.new
    @assistant = assistant
  end

  def start
    display_welcome_message
    chat_loop
  end

  private

  def display_welcome_message
    puts "\n=== Salesforce Data Analysis Chat ==="
    puts "Type 'exit' or 'quit' to end the session"
    puts "Type 'clear' to start a new conversation"
    puts "======================================\n\n"
  end

  def chat_loop
    while input = Readline.readline('You: '.green, true)
      case input.downcase
      when 'exit', 'quit'
        puts "\nGoodbye!".yellow
        break
      when 'clear'
        clear_conversation
      else
        handle_user_input(input)
      end
    end
  end

  def handle_user_input(input)
    print "Assistant: ".blue
    begin
      @assistant.add_message_and_run(content: input, auto_tool_execution: true)
    rescue => e
      puts "Error: #{e.message}".red
    end
    puts @assistant.messages.last.content
  end

  def assistant
    Langchain::Assistant.new(
      llm: @llm,
      instructions: "You're a helpful AI assistant that helps with analyzing Salesforce data stored in AWS Athena.",
      tools: [@tool]
    )
    # do |response_chunk|
    #  print(response_chunk.inspect)
    #  print_response(response_chunk)
    # end
  end

  def clear_conversation
    @assistant = assistant
    puts "\nConversation cleared. Starting fresh!".yellow
  end

  def print_response(response_chunk)
    if response_chunk['delta'] && response_chunk['delta']['text']
      text = response_chunk['delta']['text']
      print text
      $stdout.flush
    end
  end
end
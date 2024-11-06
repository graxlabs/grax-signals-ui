require 'aws-sdk-athena'
require 'csv'

class AthenaQueryTool
  extend Langchain::ToolDefinition

  define_function :execute_query, description: "AthenaQueryTool: Execute a SQL query on AWS Athena" do
    property :query, type: "string", description: "The SQL query to execute on Athena", required: true
  end

  def initialize
    @client = Aws::Athena::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    @output_bucket = ENV['ATHENA_OUTPUT_BUCKET']
  end

  def execute_query(query:)
    #puts("Executing query: #{query}")
    query_execution_id = start_query(query)
    wait_for_query_to_complete(query_execution_id)
    results = format_results(download_results(query_execution_id))
    #print("Results: #{results}")  
    results
  rescue StandardError => e
    "Error executing query: #{e.message}"
  end

  private

  def start_query(query)
    response = @client.start_query_execution({
      query_string: query,
      result_configuration: {
        output_location: @output_bucket
      }
    })
    response.query_execution_id
  end

  def wait_for_query_to_complete(query_execution_id)
    loop do
      response = @client.get_query_execution({ query_execution_id: query_execution_id })
      state = response.query_execution.status.state
      break if state == 'SUCCEEDED'
      raise "Query Failed: #{response.query_execution.status.state_change_reason}" if state == 'FAILED'
      sleep 1
    end
  end

  def download_results(query_execution_id)
    response = @client.get_query_results({ query_execution_id: query_execution_id })
    response.result_set.rows.map { |row| row.data.map(&:var_char_value) }
  end

  def format_results(results)
    return "No results found" if results.empty?
    
    # Assuming first row contains headers
    headers = results.first
    data = results[1..]
    
    # Format as readable text
    output = []
    data.each do |row|
      row_data = headers.zip(row).map { |header, value| "#{header}: #{value}" }.join(", ")
      output << row_data
    end
    
    output.join("\n")
  end
end
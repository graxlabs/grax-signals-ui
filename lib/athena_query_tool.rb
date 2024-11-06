require 'aws-sdk-athena'
require 'csv'

class AthenaQueryTool
  extend Langchain::ToolDefinition
  extend Forwardable

  define_function :execute_query, description: "AthenaQueryTool: Execute a SQL query on AWS Athena" do
    property :query, type: "string", description: "The SQL query to execute on Athena", required: true
  end

  def_delegators :@athena_client, :execute_query

  def initialize
    @athena_client = AthenaQuery.new
  end

  # Override execute_query to handle the named parameter and format results
  def execute_query(query:)
    results = @athena_client.execute_query(query)
    format_results(results)
  rescue StandardError => e
    "Error executing query: #{e.message}"
  end

  private

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
require 'aws-sdk-athena'
require 'csv'

class AthenaQuery
  def initialize
    @client = Aws::Athena::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    @output_bucket = ENV['ATHENA_OUTPUT_BUCKET']
  end

  def execute_query(query)
    query_execution_id = start_query(query)
    wait_for_query_to_complete(query_execution_id)
    download_results(query_execution_id)
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
      if state == 'FAILED'
        puts response.query_execution.status.state_change_reason
        puts response.inspect
        raise 'Query Failed'
      end
      sleep 2
    end
  end

  def download_results(query_execution_id)
    all_rows = []
    next_token = nil

    loop do
      response = @client.get_query_results({
        query_execution_id: query_execution_id,
        next_token: next_token
      })

      # Extract rows from this page
      rows = response.result_set.rows.map { |row| row.data.map(&:var_char_value) }
      all_rows.concat(rows)

      # Check if there are more results
      next_token = response.next_token
      break unless next_token
    end

    all_rows
  end
end

require 'restforce'
require 'salesforce_bulk_api'

class SalesforceBulk
  def initialize
    @client = Restforce.new(
      username:       ENV['SALESFORCE_USERNAME'],
      password:       ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      host:           ENV['SFDC_HOST'],
      client_id:      ENV['SFDC_CLIENT_ID'],
      client_secret:  ENV['SFDC_CLIENT_SECRET']
    )
    @salesforce = nil
  end

  def update_records(object_type, records)
    authenticate_client unless @salesforce
    result = @salesforce.update(object_type, records)
    id = result['id'].first
    Rails.logger.info "Salesforce job created with ID: #{id}"
    job = @salesforce.job_from_id(id)
    while job.check_job_status["numberBatchesInProgress"].first.to_i >= 1
      Rails.logger.info "waiting for job to complete"
      job = @salesforce.job_from_id(id)
      sleep 1
    end
    job.check_job_status['numberRecordsProcessed'].first.to_i
  end

  private

  def authenticate_client
    response = @client.authenticate!
    @salesforce = SalesforceBulkApi::Api.new(@client)
  end
end

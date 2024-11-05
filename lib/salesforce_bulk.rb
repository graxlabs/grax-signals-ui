require 'restforce'
require 'salesforce_bulk_api'

class SalesforceBulk
  def initialize
    client = Restforce.new(
      username:       ENV['SALESFORCE_USERNAME'],
      password:       ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      host:           ENV['SFDC_HOST'],
      client_id:      ENV['SFDC_CLIENT_ID'],
      client_secret:  ENV['SFDC_CLIENT_SECRET']
    )
    response = client.authenticate!
    @salesforce = SalesforceBulkApi::Api.new(client)
  end

  def update_records(object_type, records)
    job = @salesforce.update(object_type, records)
    puts "Salesforce job created with ID: #{job["id"]}"
    puts "Job status: #{job["state"]}"
    print job
  end
end

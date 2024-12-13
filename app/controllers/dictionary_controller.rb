class DictionaryController < ApplicationController
    def index
        client = Restforce.new(
            username:       ENV['SALESFORCE_USERNAME'],
            password:       ENV['SALESFORCE_PASSWORD'],
            security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
            host:           ENV['SFDC_HOST'],
            client_id:      ENV['SFDC_CLIENT_ID'],
            client_secret:  ENV['SFDC_CLIENT_SECRET']
          )
          client.authenticate!
          
          query = "SELECT QualifiedApiName, DataType, Label, Description, LastModifiedById, BusinessOwnerId FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Lead'"
          response = client.get("/services/data/v57.0/tooling/query?q=#{URI.encode_www_form_component(query)}")
          @definitions = response.body
          
          # collect BusinessOwnerId values
          business_owner_ids = @definitions.map { |record| record['BusinessOwnerId'] }.uniq
          puts "business_owner_ids: #{business_owner_ids}"

          # collect Id to Name
          query = "SELECT Id, Name FROM User WHERE Id IN ('#{business_owner_ids.join("','")}')"
          res = client.query(query)
        puts @business_owners = res.map { |record| [record['Id'], record['Name']] }.to_h
    end
end
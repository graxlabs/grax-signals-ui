namespace :data do
  desc "Update field description in Salesforce (usage: rake data:update_description['field_name','new description'])"
  task :update_custom_desc, [:object_name, :field_name, :description] => :environment do |t, args|
    args.with_defaults(
      object_name: 'Lead',
      field_name: 'contact_accuracy_grade__c',
      description: 'TEST - a new description'
    )

    client = Restforce.new(
      username:       ENV['SALESFORCE_USERNAME'],
      password:       ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      host:           ENV['SFDC_HOST'],
      client_id:      ENV['SFDC_CLIENT_ID'],
      client_secret:  ENV['SFDC_CLIENT_SECRET']
    )
    client.authenticate!

    query = "SELECT Id, DeveloperName, Metadata FROM CustomField WHERE TableEnumOrId = '#{args.object_name}' AND DeveloperName = '#{args.field_name.sub('__c', '')}'"
    field_response = client.get("/services/data/v57.0/tooling/query?q=#{URI.encode_www_form_component(query)}")
    field_record = field_response.body.first

    field_id = field_record['Id']
    current_metadata = field_record['Metadata']

    # Update just the description in the metadata
    update_body = {
      Metadata: current_metadata.merge({
        description: args.description
      })
    }

    result = client.patch("/services/data/v57.0/tooling/sobjects/CustomField/#{field_id}", update_body)
    if result.status.to_s.start_with?('20')
      puts "Successfully updated #{args.object_name} field #{args.field_name} description to '#{args.description}'"
    else
      puts "Failed to update field description: #{result.inspect}"
    end
  end

  desc "Update standard field description in Salesforce (usage: rake data:update_standard_desc['object_name','field_name','new description'])"
  task :update_standard_desc, [:object_name, :field_name, :description] => :environment do |t, args|
    args.with_defaults(
      object_name: 'Lead',
      field_name: 'Company',
      description: 'TEST - a new description'
    )

    client = Restforce.new(
      username:       ENV['SALESFORCE_USERNAME'],
      password:       ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      host:           ENV['SFDC_HOST'],
      client_id:      ENV['SFDC_CLIENT_ID'],
      client_secret:  ENV['SFDC_CLIENT_SECRET']
    )
    client.authenticate!

    # Get the entity definition first
    entity_query = "SELECT Id, DeveloperName FROM EntityDefinition WHERE QualifiedApiName = '#{args.object_name}'"
    entity_response = client.get("/services/data/v57.0/tooling/query?q=#{URI.encode_www_form_component(entity_query)}")
    entity_record = entity_response.body.first

    if entity_record.nil?
      puts "Object not found: #{args.object_name}"
      return
    end

    # List all fields using EntityParticle
    fields_query = "SELECT Id, DurableId, QualifiedApiName, Label FROM EntityParticle WHERE EntityDefinition.QualifiedApiName = '#{args.object_name}'"
    fields_response = client.get("/services/data/v57.0/tooling/query?q=#{URI.encode_www_form_component(fields_query)}")

    # Find the field case-insensitively
    field_record = fields_response.body.find do |record|
      record['QualifiedApiName'].downcase == args.field_name.downcase
    end

    if field_record.nil?
      puts "Field not found: #{args.field_name} on object #{args.object_name}"
      puts "Available fields:"
      fields_response.body.each do |record|
        puts "- #{record['QualifiedApiName']}"
      end
    end

    # Get current metadata
    metadata_query = "SELECT Id, Metadata FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = '#{args.object_name}' AND QualifiedApiName = '#{field_record['QualifiedApiName']}'"
    metadata_response = client.get("/services/data/v57.0/tooling/query?q=#{URI.encode_www_form_component(metadata_query)}")
    metadata_record = metadata_response.body.first
    current_metadata = metadata_record['Metadata']

    puts "Metadata Response: #{metadata_response.body.inspect}"
    puts "Metadata Record: #{metadata_record.inspect}"

    # Use the URL from the metadata record's attributes
    field_definition_url = metadata_record['attributes']['url']

    # Update the field description
    update_body = {
      fullName: "#{args.object_name}.#{field_record['QualifiedApiName']}",
      Metadata: current_metadata.merge({
        description: args.description
      })
    }

    puts "Field Definition URL: #{field_definition_url}"
    puts "Updating with body: #{update_body.inspect}"
    result = client.patch(field_definition_url, update_body)

    if result.status.to_s.start_with?('20')
      puts "Successfully updated #{args.object_name} field #{field_record['QualifiedApiName']} description to '#{args.description}'"
    else
      puts "Failed to update field description: #{result.body}"
    end
  end
end
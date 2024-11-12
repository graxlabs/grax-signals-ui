require 'test_helper'
require 'minitest/mock'

class SalesforceBulkTest < ActiveSupport::TestCase
  def setup
    @salesforce_bulk = SalesforceBulk.new
    @salesforce_mock = Minitest::Mock.new
    @salesforce_bulk.instance_variable_set(:@salesforce, @salesforce_mock)
  end

  test "update_records" do
    object_type = 'Account'
    records = [{ 'Id' => '001xx000003DGbVAAW', 'Name' => 'Test Account' }]

    job_mock = Minitest::Mock.new
    job_mock.expect :check_job_status, { "numberBatchesInProgress" => ["0"], "numberRecordsProcessed" => ["1"] }, []
    job_mock.expect :check_job_status, { "numberBatchesInProgress" => ["0"], "numberRecordsProcessed" => ["1"] }, []

    @salesforce_mock.expect :update, { 'id' => ['750xx0000008VZVAA2'] }, [object_type, records]
    @salesforce_mock.expect :job_from_id, job_mock, ['750xx0000008VZVAA2']

    result = @salesforce_bulk.update_records(object_type, records)
    assert_equal 1, result

    @salesforce_mock.verify
    job_mock.verify
  end

  test "update_records with job in progress" do
    object_type = 'Account'
    records = [{ 'Id' => '001xx000003DGbVAAW', 'Name' => 'Test Account' }]

    job_mock = Minitest::Mock.new
    job_mock.expect :check_job_status, { "numberBatchesInProgress" => ["1"], "numberRecordsProcessed" => ["0"] }, []
    job_mock.expect :check_job_status, { "numberBatchesInProgress" => ["0"], "numberRecordsProcessed" => ["1"] }, []
    job_mock.expect :check_job_status, { "numberBatchesInProgress" => ["0"], "numberRecordsProcessed" => ["1"] }, []

    @salesforce_mock.expect :update, { 'id' => ['750xx0000008VZVAA2'] }, [object_type, records]
    @salesforce_mock.expect :job_from_id, job_mock, ['750xx0000008VZVAA2']
    @salesforce_mock.expect :job_from_id, job_mock, ['750xx0000008VZVAA2']

    result = @salesforce_bulk.update_records(object_type, records)
    assert_equal 1, result

    @salesforce_mock.verify
    job_mock.verify
  end

  test "update_records handles errors" do
    object_type = 'Account'
    records = [{ 'Id' => '001xx000003DGbVAAW', 'Name' => 'Test Account' }]

    @salesforce_mock.expect :update, -> { raise StandardError, "Update failed" }, [object_type, records]

    assert_raises(StandardError) do
      @salesforce_bulk.update_records(object_type, records)
    end

    @salesforce_mock.verify
  end
end

require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/requests/v3/public/list_projects' do

    validate_response "session is validated" do
      @session = Aviator::Session.new(
        config_file: Environment.path,
        environment: 'openstack_admin',
        log_file:    Environment.log_file_path
      )
      @session.authenticate
      keystone = @session.identity_service
      response = keystone.request(:list_projects, :api_version => :v3)
      response.status.must_equal(200)
    end
  end

end

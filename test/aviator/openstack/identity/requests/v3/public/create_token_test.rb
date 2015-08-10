require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/requests/v3/public/create_token' do

    validate_response 'parameters are valid' do
      service = Aviator::Service.new(
        provider: 'openstack',
        log_file: Environment.log_file_path,
        service:  'identity',
        default_session_data: RequestHelper.admin_bootstrap_session_data(:v3)
      )

      response = service.request :create_token, :api_version => :v3 do |params|
        params[:username] = Environment.openstack_admin[:auth_credentials][:username]
        params[:password] = Environment.openstack_admin[:auth_credentials][:password]
        params[:domainId] = 'default'
      end

      [200, 201].include?(response.status).must_equal true

      response.body.wont_be_nil
      response.headers.wont_be_nil
    end

    validate_response "session is valid" do
      @session = Aviator::Session.new(
        config_file: Environment.path,
        environment: 'openstack_admin'
      )
      @session.authenticate
      @session.authenticated?.must_equal true
    end

    validate_response "session is validated" do
      @session = Aviator::Session.new(
        config_file: Environment.path,
        environment: 'openstack_admin',
        log_file: Environment.log_file_path
      )
      @session.authenticate

      @session.validate.must_equal true

    end
  end

end

require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/requests/v2/admin/list_roles' do

    def create_request(session_data = get_session_data, &block)
      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_response
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'identity', 'v2', 'admin', 'list_roles.rb')
    end


    def session
      unless @session
        @session = Aviator::Session.new(
          config_file: Environment.path,
          environment: 'openstack_admin'
        )
        @session.authenticate
      end

      @session
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v2
    end


    validate_attr :body do
      klass.body?.must_equal false
      create_request.body?.must_equal false
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :admin
    end


    validate_attr :headers do
      session_data = get_session_data

      headers = { 'X-Auth-Token' => session_data[:body][:access][:token][:id] }

      request = create_request(session_data)

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :get
    end


    validate_attr :url do
      session_data = get_session_data
      identity_url = session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'identity' }[:endpoints][0]['adminURL']
      url          = "#{ identity_url }/OS-KSADM/roles/"
      request      = klass.new(session_data)

      request.url.must_equal url
    end


    validate_response 'no parameters are provided' do
      service = session.identity_service

      response = service.request :list_roles, :api_version => :v2

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:roles].length.wont_equal 0
      response.headers.wont_be_nil
    end


  end

end
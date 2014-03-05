#require 'test_helper'
require_relative "../../../../../test_helper"

class Aviator::Test

  describe 'aviator/openstack/identity/v2/admin/get_user' do



    def create_request(session_data = get_session_data)
      klass.new(session_data) do |p|
        p[:id] = get_user_id
      end
    end


    def get_session_data
      session.send :auth_info
    end

    def get_user_id
      get_session_data['access']['user']['id']
    end

    def get_user_name
      get_session_data['access']['user']['username']
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'identity', 'v2', 'admin', 'get_user.rb')
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

      headers = { 'X-Auth-Token' => session_data[:access][:token][:id] }

      request = create_request(session_data)

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :get
    end


    validate_attr :url do
      session_data = get_session_data
      service_spec = session_data[:access][:serviceCatalog].find{|s| s[:type] == 'identity' }
      url          = "#{ service_spec[:endpoints][0][:adminURL] }/users/#{get_user_id}"
      request      = klass.new(session_data) do |p|
        p.id = get_user_id
      end

      request.url.must_equal url
    end


    validate_response 'no parameters are provided' do
      service = session.identity_service

      response = service.request :get_user do |p|
        p.id = get_user_id
      end


      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:user].length.wont_equal 0
      response.body[:user]['name'] = get_user_name
      response.headers.wont_be_nil
    end


  end

end

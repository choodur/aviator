require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/requests/v2/admin/list_user_roles_on_tenant' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:tenant_id] = 0
                  params[:user_id] = 0
                end

      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_response
    end


    def helper
      Aviator::Test::OpenstackHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'identity', 'v2', 'admin', 'list_user_roles_on_tenant.rb')
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
      tenant_id = 'sample_tenant_id'
      user_id = 'sample_user_id'
      session_data = get_session_data
      identity_url = session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'identity' }[:endpoints][0]['adminURL']
      url          = "#{ identity_url }/tenants/#{ tenant_id }/users/#{ user_id }/roles"

      request = create_request do |p|
        p[:tenant_id] = tenant_id
        p[:user_id] = user_id
      end

      request.url.must_equal url
    end


    validate_response 'valid ids are provided' do
      tenant_id = helper.get_project(session, 'admin')[:id]
      user_id   = helper.get_user(session, 'admin')[:id]

      response = session.identity_service.request :list_user_roles_on_tenant, :api_version => :v2 do |params|
        params[:tenant_id] = tenant_id
        params[:user_id]   = user_id
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:roles].wont_be_nil
      response.headers.wont_be_nil
    end


    validate_response 'invalid tenant_id is provided' do
      tenant_id = 'tenantDoesNotExist'
      user_id   = helper.get_user(session, 'admin')[:id]

      response = session.identity_service.request :list_user_roles_on_tenant, :api_version => :v2 do |params|
        params[:tenant_id] = tenant_id
        params[:user_id]   = user_id
      end

      response.status.must_equal 404
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end


    validate_response 'invalid user_id is provided' do
      tenant_id = helper.get_project(session, 'admin')[:id]
      user_id   = 'userDoesNotExist'

      response = session.identity_service.request :list_user_roles_on_tenant, :api_version => :v2 do |params|
        params[:tenant_id] = tenant_id
        params[:user_id]   = user_id
      end

      response.status.must_equal 404
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end


  end

end

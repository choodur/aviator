require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/admin/remove_flavor_from_project' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:flavor_id] = 0
                  params[:tenant] = ''
                end

      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_response
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'admin', 'remove_flavor_from_project.rb')
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


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :admin
    end


    validate_attr :headers do
      headers = { 'X-Auth-Token' => get_session_data[:body][:access][:token][:id] }

      request = create_request

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :post
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end


    validate_attr :required_params do
      klass.required_params.must_equal [
        :flavor_id,
        :tenant
      ]
    end


    def create_flavor
      response = session.compute_service.request :create_flavor, :api_version => :v2 do |params|
        params[:disk] = '1'
        params[:ram] = '1'
        params[:vcpus] = '1'
        params[:name] = 'testflavor'
      end

      response.body[:flavor]
    end


    def add_access(flavor_id, tenant_id)
      response = session.compute_service.request :add_project_flavor, :api_version => :v2 do |params|
        params[:tenant_id] = tenant_id
        params[:flavor_id] = flavor_id
      end
      response.body[:flavor_access]
    end


    def delete_flavor(id)
      session.compute_service.request :delete_flavor, :api_version => :v2 do |params|
        params[:flavor_id] = id
      end
    end


    validate_attr :url do
      flavor_id   = 'sample_flavor_id'
      tenant      = 'sample_tenant'
      compute_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['adminURL']
      url         = "#{ compute_url }/flavors/#{ flavor_id }/action"

      request = create_request do |p|
        p[:flavor_id] = flavor_id
        p[:tenant] = tenant
      end

      request.url.must_equal url
    end


    validate_response 'valid params are provided' do
      tenant    = session.identity_service.request(:list_tenants, :api_version => :v2).body[:tenants].first
      tenant_id = tenant[:id]
      flavor    = create_flavor
      flavor_id = flavor[:id]
      add_access(flavor_id, tenant_id)

      response = session.compute_service.request :remove_flavor_from_project, :api_version => :v2 do |params|
        params[:flavor_id] = flavor_id
        params[:tenant] = tenant_id
      end

      response.status.must_equal 200
      response.body[:flavor_access].wont_be_nil
      response.headers.wont_be_nil

      delete_flavor(flavor_id)
    end


    validate_response 'invalid tenant is provided' do
      # must be hardcoded so as not to inadvertently alter random resources
      # in case the corresponding cassette is deleted
      flavor_id = '100'
      tenant = 'abogustenantidthatdoesnotexist'

      response = session.compute_service.request :remove_flavor_from_project, :api_version => :v2 do |params|
        params[:flavor_id] = flavor_id
        params[:tenant] = tenant
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
    end

  end

end

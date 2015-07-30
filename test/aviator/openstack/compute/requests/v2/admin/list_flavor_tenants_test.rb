require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/v2/admin/list_flavor_tenants' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:flavor_id] = 'test_flavor_id'
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
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'admin', 'list_flavor_tenants.rb')
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


    def create_flavor
      response = session.compute_service.request :create_flavor do |params|
        params[:disk] = '1'
        params[:ram] = '1'
        params[:vcpus] = '1'
        params[:name] = 'testflavor'
        params[:'os-flavor-access:is_public'] = false
      end
      response.body[:flavor]
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

      headers = { 'X-Auth-Token' => session_data.token }

      request = create_request(session_data)

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :get
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:flavor_id]
    end


    validate_attr :url do
      flavor_id    = 'test_flavor_id'
      session_data = get_session_data
      service_spec = session_data[:catalog].find{ |s| s[:type] == 'compute' }
      url          = "#{ service_spec[:endpoints].find{|e| e[:interface] == 'admin'}[:url] }/flavors/test_flavor_id/os-flavor-access"
      request      = create_request

      request.url.must_equal url
    end


    validate_response 'valid flavor_id parameter is provided' do
      # TODO: when params[:'os-flavor-access:is_public'] is supported
      #       for create_flavor this should be updated
      # tenant    = session.identity_service.request(:list_tenants).body[:tenants].first
      # tenant_id = tenant[:id]
      # flavor    = create_flavor
      # flavor_id = flavor[:id]
      # add_access(flavor_id, tenant_id)

      flavor_id = "100"
      service = session.compute_service

      response = service.request :list_flavor_tenants do |params|
        params[:flavor_id] = flavor_id
      end

      response.status.must_equal 200
      response.headers.wont_be_nil
      response.body.wont_be_nil
      response.body[:flavor_access].length.wont_equal 0

      response.body[:flavor_access].each do |fa|
        fa[:tenant_id].wont_be_nil
        fa[:flavor_id].must_equal flavor_id
      end
    end


    validate_response 'invalid zone parameter is provided' do
      service = session.compute_service

      response = service.request :list_flavor_tenants do |params|
        params[:flavor_id] = 'nonexistentfalseflavorid'
      end

      response.status.must_equal 404
      response.body.wont_be_nil
      response.body[:flavor_access].must_be_nil
      response.headers.wont_be_nil
    end

  end

end


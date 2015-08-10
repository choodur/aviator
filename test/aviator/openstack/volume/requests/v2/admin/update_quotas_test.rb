require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/v2/admin/update_quotas' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:tenant_id] = 'theTenant'
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
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'admin', 'update_quotas.rb')
    end


    def tenant_id
      return @tenant_id unless @tenant_id.nil?

      response   = session.identity_service.request(:list_tenants, :api_version => :v2)
      @tenant_id = response.body[:tenants].last[:id]
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


    def v2_base_url
      unless @v2_base_url
        @v2_base_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'volumev2' }[:endpoints][0]['adminURL']
      end

      @v2_base_url
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v2
    end


    validate_attr :body do
      request = create_request

      klass.body?.must_equal true
      request.body?.must_equal true
      request.body.wont_be_nil
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :admin
    end


    validate_attr :headers do
      session_data = get_session_data

      headers = { 'X-Auth-Token' => session_data[:body][:access][:token][:id] }

      create_request(session_data).headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :put
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal [:gigabytes, :snapshots, :volumes, :custom_quotas]
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:tenant_id]
    end


    validate_attr :url do
      url    = "#{ v2_base_url }/os-quota-sets/#{ tenant_id }"
      tenant = tenant_id

      request = klass.new(get_session_data) do |p|
        p[:tenant_id] = tenant
      end

      request.url.must_equal url
    end


    optionals = Aviator::Test::RequestHelper.load_request('openstack', 'volume', 'v2', 'admin', 'update_quotas.rb')
                                            .optional_params

    defaults = optionals - [:custom_quotas]

    defaults.each do |param|
      validate_response "valid #{param} params is provided" do
        value = 10
        tenant = tenant_id

        response = session.volume_service.request(:update_quotas, :api_version => :v2) do |params|
          params[:tenant_id]  = tenant
          params[param]       = value
        end

        response.status.must_equal 200
        response.body.wont_be_nil
        response.body[:quota_set].wont_be_nil
        response.body[:quota_set][param].must_equal value
        response.headers.wont_be_nil
      end
    end

    defaults.each do |param|
      validate_response "invalid #{param} params is provided" do
        value = 'stringyValue'
        tenant = tenant_id

        response = session.volume_service.request(:update_quotas, :api_version => :v2) do |params|
          params[:tenant_id]  = tenant
          params[param]       = value
        end

        response.status.must_equal 200
        response.body.wont_be_nil
        response.body[:quota_set].wont_be_nil
        response.body[:quota_set][param].must_equal 0
        response.headers.wont_be_nil
      end
    end

    validate_response 'custom quotas are from volume types' do
      create_type = session.volume_service.request(:create_volume_type, :api_version => :v2) do |params|
        params[:name] = 'quota-test'
      end

      volume_type = create_type.body[:volume_type]
      volume_type.wont_be_empty

      limit            = 10
      custom_gigabytes = "gigabytes_#{volume_type[:name]}"
      custom_snapshots = "snapshots_#{volume_type[:name]}"
      custom_volumes   = "volumes_#{volume_type[:name]}"

      response = session.volume_service.request(:update_quotas, :api_version => :v2) do |params|
        params[:tenant_id]     = tenant_id
        params[:custom_quotas] = {
          custom_gigabytes => limit,
          custom_snapshots => limit,
          custom_volumes   => limit
        }
      end

      response.status.must_equal 200
      response.body[:quota_set].wont_be_nil
      response.body[:quota_set][custom_gigabytes].must_equal limit
      response.body[:quota_set][custom_snapshots].must_equal limit
      response.body[:quota_set][custom_volumes].must_equal limit

      session.volume_service.request(:delete_volume_type, :api_version => :v2) do |params|
        params[:id] = volume_type[:id]
      end
    end

    validate_response 'custom quotas do not exist' do
      limit            = 10
      dummy_type       = 'ae35dfe'
      custom_gigabytes = "gigabytes_#{dummy_type}"
      custom_snapshots = "snapshots_#{dummy_type}"
      custom_volumes   = "volumes_#{dummy_type}"


      list = session.volume_service.request(:list_volume_types, :api_version => :v2)

      list.body[:volume_types].find { |type| type[:name] == dummy_type }.must_be_nil

      response = session.volume_service.request(:update_quotas, :api_version => :v2) do |params|
        params[:tenant_id]     = tenant_id
        params[:custom_quotas] = {
          custom_gigabytes => limit,
          custom_snapshots => limit,
          custom_volumes   => limit
        }
      end

      response.status.must_equal 400
    end
  end

end

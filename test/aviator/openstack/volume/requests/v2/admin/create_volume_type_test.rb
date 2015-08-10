require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/v2/admin/create_volume_type' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
        params[:name]        = 'test'
        params[:extra_specs] = { capabilities: 'testing' }
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
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'admin', 'create_volume_type.rb')
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
      klass.optional_params.must_equal [:extra_specs]
    end

    validate_attr :required_params do
      klass.required_params.must_equal [:name]
    end

    validate_response 'valid parameters are provided' do
      response = session.volume_service.request(:create_volume_type, :api_version => :v2) do |params|
        params[:name]        = 'SATA'
        params[:extra_specs] = { capabilities: 'gpu' }
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volume_type].wont_be_nil
      response.headers.wont_be_nil

      session.volume_service.request(:delete_volume_type, :api_version => :v2) do |params|
        params[:id] = response.body[:volume_type][:id]
      end
    end
  end

end

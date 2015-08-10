require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/v2/admin/delete_volume_type' do

    def create_volume_type
      response = session.volume_service.request :create_volume_type, :api_version => :v2 do |params|
        params[:name] = 'test'
      end

      @type = response.body[:volume_type]
    end

    def get_session_data
      session.send :auth_response
    end

    def helper
      Aviator::Test::RequestHelper
    end

    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'admin', 'delete_volume_type.rb')
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

    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end

    validate_attr :required_params do
      klass.required_params.must_equal [:id]
    end

    validate_response 'parameters are provided' do
      volume_type = create_volume_type

      volume_type.wont_be_empty

      response = session.volume_service.request(:delete_volume_type, :api_version => :v2) do |params|
        params[:id] = volume_type[:id]
      end

      response.status.must_equal 202

      list = session.volume_service.request(:list_volume_types, :api_version => :v2)
      list.body[:volume_types].find { |type| type[:id] == volume_type[:id] }.must_be_nil
    end

  end

end

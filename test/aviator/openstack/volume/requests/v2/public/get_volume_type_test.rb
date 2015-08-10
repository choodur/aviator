require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/v2/public/get_volume_type' do

    def get_session_data
      session.send :auth_response
    end

    def helper
      Aviator::Test::RequestHelper
    end

    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'public', 'get_volume_type.rb')
    end

    def session
      unless @session
        @session = Aviator::Session.new(
                     config_file: Environment.path,
                     environment: 'openstack_admin' # so we can create a volume type
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

    validate_response 'parameters are provided' do
      create = session.volume_service.request(:create_volume_type, :api_version => :v2) do |params|
        params[:name] = 'SSD'
      end

      volume_type = create.body[:volume_type]
      volume_type.wont_be_empty

      response = session.volume_service.request(:get_volume_type, :api_version => :v2) do |params|
        params[:id] = volume_type[:id]
      end

      response.status.must_equal 200
      response.body[:volume_type].wont_be_nil
      response.body[:volume_type][:name].must_equal volume_type[:name]


      session.volume_service.request(:delete_volume_type, :api_version => :v2) do |params|
        params[:id] = volume_type[:id]
      end
    end
  end
end

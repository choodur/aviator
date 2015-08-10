require 'test_helper'

class Aviator::Test
  describe 'aviator/openstack/volume/requests/v1/public/update_volume' do
    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
        params[:id] = 0
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
      @klass ||= helper.load_request('openstack', 'volume', 'v1', 'public', 'update_volume.rb')
    end


    def session
      unless @session
        @session = Aviator::Session.new(
                     config_file: Environment.path,
                     environment: 'openstack_member'
                   )
        @session.authenticate
      end

      @session
    end

    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v1
    end


    validate_attr :body do
      request = create_request
      klass.body?.must_equal true
      request.body?.must_equal true
      request.body.wont_be_nil
    end

    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :public
    end

    validate_attr :headers do
      headers = { 'X-Auth-Token' => get_session_data[:body][:access][:token][:id] }

      request = create_request

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :put
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal [
        :display_name,
        :display_description,
        :metadata
      ]
    end

    validate_attr :required_params do
      klass.required_params.must_equal [
        :id
      ]
    end

    validate_attr :url do
      volume_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'volume' }[:endpoints][0]['publicURL']
      volume_id  = 'doesitmatter'
      url        = "#{ volume_url }/volumes/#{ volume_id }"

      request = create_request do |params|
        params[:id] = volume_id
      end

      request.url.must_equal url
    end

    validate_response 'valid volume id is provided' do
      volume    = session.volume_service.request(:list_volumes, :api_version => :v1).body[:volumes].first
      volume_id = volume[:id]
      new_name  = 'Aviator Test Update Volume'

      response = session.volume_service.request :update_volume, :api_version => :v1 do |params|
        params[:id]           = volume_id
        params[:display_name] = new_name
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volume].wont_be_nil
      response.body[:volume][:display_name].must_equal new_name
      response.headers.wont_be_nil
    end

    validate_response 'valid metadata is provided' do
      response = session.volume_service.request(:create_volume, :api_version => :v1) do |p|
        p.display_name        = 'update-volume-test'
        p.display_description = 'update-volume-test description'
        p.size                = 1
      end
      volume_id = response.body[:volume][:id]

      sleep 5 if VCR.current_cassette.recording?

      response = session.volume_service.request(:update_volume, :api_version => :v1) do |p|
        p.id       = volume_id
        p.metadata = { test_key: 'test_value' }
      end

      response.status.must_equal 200
      response.body.wont_be_nil

      response = session.volume_service.request(:get_volume, :api_version => :v1) { |p| p.id = volume_id }
      response.body[:volume][:metadata].keys.must_include 'test_key'
      response.body[:volume][:metadata][:test_key].must_equal 'test_value'

      session.volume_service.request(:delete_volume, :api_version => :v1) { |p| p.id = volume_id }
    end

    validate_response 'invalid volume id is provided' do
      volume_id = 'ithinkiexist'

      response = session.volume_service.request :update_volume, :api_version => :v1 do |params|
        params[:id]   = volume_id
        params[:display_name] = 'it does not matter'
      end

      response.status.must_equal 404
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end
  end
end

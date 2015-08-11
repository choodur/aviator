require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/requests/v1/public/get_volume' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
        params[:id] = 0
      end

      klass.new(session_data, &block)
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


    def get_session_data
      session.send :auth_response
    end


    def helper
      Aviator::Test::OpenstackHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v1', 'public', 'get_volume.rb')
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v1
    end


    validate_attr :body do
      klass.body?.must_equal false

      request = create_request
      request.body?.must_equal false
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
      request = create_request
      request.http_method.must_equal :get
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:id]
    end


    validate_attr :url do
      volume_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'volume' }[:endpoints][0]['publicURL']
      volume_id    = '52415800-8b69-11e0-9b19-734f000004d2'
      url          = "#{ volume_url }/volumes/#{ volume_id }"

      request = create_request do |p|
        p[:id] = volume_id
      end

      request.url.must_equal url
    end


    validate_response 'a valid volume id is provided' do
      volume = helper.create_volume(session).body[:volume]

      response = session.volume_service.request :get_volume, :api_version => :v1 do |params|
        params[:id] = volume[:id]
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volume].wont_be_nil
      response.body[:volume][:id].must_equal volume[:id]
      response.headers.wont_be_nil

      helper.delete_volume(session, volume[:id])
    end

    validate_response 'an invalid volume id is provided' do
      volume_id = 'bogusserveridthatdoesntexist'

      response = session.volume_service.request :get_volume, :api_version => :v1 do |params|
        params[:id] = volume_id
      end

      response.status.must_equal 404
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end

  end
end

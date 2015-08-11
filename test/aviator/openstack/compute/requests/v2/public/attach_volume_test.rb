require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/public/attach_volume' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:server_id] = 'serverDoesNotExist'
                  params[:volume_id] = 'volumeDoesNotExist'
                  params[:device] = '/dev/xvdb'
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
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'public', 'attach_volume.rb')
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
      klass.api_version.must_equal :v2
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
      create_request.http_method.must_equal :post
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:server_id, :volume_id, :device]
    end


    validate_attr :url do
      session_data = get_session_data
      compute_url  = session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['publicURL']
      server       = helper.create_server(session).body[:server]
      volume       = helper.create_volume(session).body[:volume]
      device       = '/dev/xvdb'
      url          = "#{ compute_url }/servers/#{ server[:id] }/os-volume_attachments"

      request = create_request do |params|
        params[:server_id]  = server[:id]
        params[:volume_id]  = volume[:id]
        params[:device]     = device
      end

      request.url.must_equal url

      helper.delete_volume(session, volume[:id])
      helper.delete_server(session, server[:id])
    end


    validate_response 'valid parameters are provided' do
      server = helper.create_server(session).body[:server]
      volume = helper.create_volume(session).body[:volume]
      device = '/dev/xvdb'

      response = session.compute_service.request :attach_volume, :api_version => :v2 do |params|
        params[:server_id]  = server[:id]
        params[:volume_id]  = volume[:id]
        params[:device]     = device
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volumeAttachment].wont_be_nil
      response.headers.wont_be_nil

      helper.delete_volume(session, volume[:id])
      helper.delete_server(session, server[:id])
    end

    validate_response 'invalid volumeId is provided' do
      volume_id = 'volumeDoesNotExist'

      response = session.compute_service.request :attach_volume, :api_version => :v2 do |params|
        params[:server_id]  = 'serverDoesNotExist'
        params[:volume_id]  = volume_id
        params[:device]     = '/dev/xvdb'
      end

      response.status.must_equal 400
      response.headers.wont_be_nil
      response.body['badRequest'].wont_be_nil
      response.body['badRequest']['message'].must_equal "Bad volumeId format: volumeId is not in proper format (#{volume_id})"
    end

    validate_response 'non existent server is provided' do
      volume = helper.create_volume(session).body[:volume]

      response = session.compute_service.request :attach_volume, :api_version => :v2 do |params|
        params[:server_id]  = 'serverDoesNotExist'
        params[:volume_id]  = volume[:id]
        params[:device]     = '/dev/xvdb'
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
      response.body['itemNotFound'].wont_be_nil
      response.body['itemNotFound']['message'].must_equal 'The resource could not be found.'

      helper.delete_volume(session, volume[:id])
    end


    validate_response 'non existent volume is provided' do
      server = helper.create_server(session).body[:server]

      response = session.compute_service.request :attach_volume, :api_version => :v2 do |params|
        params[:server_id]  = server[:id]
        params[:volume_id]  = '56121be0-1d25-1234-bb53-77e5c21449c5'
        params[:device]     = '/dev/xvdb'
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
      response.body['itemNotFound'].wont_be_nil
      response.body['itemNotFound']['message'].must_equal 'The resource could not be found.'

      helper.delete_server(session, server[:id])
    end

  end

end

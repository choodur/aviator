require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/public/detach_volume' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:server_id] = 'caae3c89-80c4-test-test-a9d7c3fce4dc'
                  params[:volume_id] = '56121be0-1d25-test-test-77e5c21449c5'
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
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'public', 'detach_volume.rb')
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

    def create_server
      image_id  = session.compute_service.request(:list_images).body[:images].first[:id]
      flavor_id = session.compute_service.request(:list_flavors).body[:flavors].first[:id]

      response = session.compute_service.request :create_server do |params|
        params[:imageRef]  = image_id
        params[:flavorRef] = flavor_id
        params[:name] = 'Aviator Server'
      end
      response
    end

    def create_volume
      response = session.volume_service.request :create_volume do |params|
        params[:display_name]         = 'Aviator Volume Test Name'
        params[:display_description]  = 'Aviator Volume Test Description'
        params[:size]                 = '1'
      end
      response
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v2
    end


    validate_attr :body do
      request = create_request
      klass.body?.must_equal false
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
      create_request.http_method.must_equal :delete
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:server_id, :volume_id]
    end

    validate_attr :url do
      compute_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['publicURL']
      server_id   = 'a6d2cdcb-test-test-test-0833c30e968e'
      volume_id   = '56121be0-test-test-test-77e5c21449c5'
      url         = "#{ compute_url }/servers/#{ server_id }/os-volume_attachments/#{ volume_id}"

      request = create_request do |params|
        params[:server_id] = server_id
        params[:volume_id] = volume_id
      end

      request.url.must_equal url
    end


    validate_response 'valid parameters are provided' do
      server = helper.create_server(session).body[:server]
      volume = helper.create_volume(session).body[:volume]

      response = session.compute_service.request :attach_volume, :api_version => :v2 do |params|
        params[:server_id]  = server[:id]
        params[:volume_id]  = volume[:id]
        params[:device]     = '/dev/vdc'
      end

      sleep 5 if VCR.current_cassette.recording?

      response = session.compute_service.request :detach_volume, :api_version => :v2 do |params|
        params[:server_id] = server[:id]
        params[:volume_id] = volume[:id]
      end

      response.status.must_equal 202

      helper.delete_volume(session, volume[:id])
      helper.delete_server(session, server[:id])
    end


    validate_response 'invalid parameters are provided' do
      server_id = 'a6d2cdcb-test-test-test-0833c30e968e'
      volume_id = '56121be0-test-test-test-77e5c21449c5'

      response = session.compute_service.request :detach_volume, :api_version => :v2 do |params|
        params[:server_id] = server_id
        params[:volume_id] = volume_id
      end

      response.status.must_equal 404
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end

  end

end

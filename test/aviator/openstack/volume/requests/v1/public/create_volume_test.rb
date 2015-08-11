require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/requests/v1/public/create_volume' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
        params[:display_name]        = 'Aviator Create Volume Name'
        params[:display_description] = 'Aviator Create Volume Description'
        params[:size]                = 1
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
      @klass ||= helper.load_request('openstack', 'volume', 'v1', 'public', 'create_volume.rb')
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
      create_request.http_method.must_equal :post
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal [
        :volume_type,
        :availability_zone,
        :snapshot_id,
        :metadata
      ]
    end


    validate_attr :required_params do
      klass.required_params.must_equal [
        :display_name,
        :display_description,
        :size
      ]
    end

    validate_attr :url do
      volume_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'volume' }[:endpoints][0]['publicURL']
      url        = "#{ volume_url }/volumes"
      request    = create_request

      request.url.must_equal url
    end

    validate_response 'parameters are provided' do
      response = session.volume_service.request :create_volume, :api_version => :v1 do |params|
        params[:display_name]         = 'Aviator Volume Test Name'
        params[:display_description]  = 'Aviator Volume Test Description'
        params[:size]                 = '1'
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volume].wont_be_nil
      response.headers.wont_be_nil

      helper.delete_volume(session, response.body[:volume][:id])
    end

  end

end

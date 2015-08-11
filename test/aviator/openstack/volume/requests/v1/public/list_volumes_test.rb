require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/requests/v1/public/list_volumes' do


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


    def create_request(session_data = get_session_data, &block)
      klass.new(session_data, &block)
    end


    def member_session
      unless @member_session
        @member_session = Aviator::Session.new(
                     config_file: Environment.path,
                     environment: 'openstack_member'
                   )
        @member_session.authenticate
      end

      @member_session
    end


    def get_session_data
      member_session.send :auth_response
    end


    def helper
      Aviator::Test::OpenstackHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v1', 'public', 'list_volumes.rb')
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v1
    end


    validate_attr :body do
      klass.body?.must_equal false
      create_request.body?.must_equal false
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :public
    end


    validate_attr :headers do
      headers = { 'X-Auth-Token' => get_session_data[:body][:access][:token][:id] }

      request = create_request

      request.headers.must_equal headers
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal [
        :all_tenants,
        :details,
        :status,
        :availability_zone,
        :bootable,
        :display_name,
        :display_description,
        :volume_type,
        :snapshot_id,
        :size
      ]
    end


    validate_attr :required_params do
      klass.required_params.must_equal []
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :get
    end


    validate_response 'all_tenants param is true' do
      # Manually create the volumes in more than one tenant for now
      volume = helper.create_volume(member_session).body[:volume]
      control_response = session.volume_service.request :list_volumes, :api_version => :v1

      all_tenants_response = session.volume_service.request :list_volumes, :api_version => :v1 do |params|
        params[:all_tenants] = true
      end

      all_tenants_response.body[:volumes].length.must_be :>, control_response.body[:volumes].length
      helper.delete_volume(session, volume[:id])
    end


    validate_response 'no parameters are provided' do
      volume = helper.create_volume(member_session).body[:volume]

      response = member_session.volume_service.request :list_volumes, :api_version => :v1

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volumes].length.wont_equal 0
      response.headers.wont_be_nil

      helper.delete_volume(session, volume[:id])
    end


    validate_response 'parameters are valid' do
      volume = helper.create_volume(member_session).body[:volume]

      response = member_session.volume_service.request :list_volumes, :api_version => :v1 do |params|
        params[:details]      = true
        params[:display_name] = volume[:name]
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volumes].select { |v| v[:display_name] == volume[:name] }.wont_be_nil
      response.headers.wont_be_nil

      helper.delete_volume(session, volume[:id])
    end


    validate_response 'parameters are invalid' do
      response = member_session.volume_service.request :list_volumes, :api_version => :v1 do |params|
        params[:display_name] = "derpderp"
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volumes].length.must_equal 0
      response.headers.wont_be_nil
    end


  end

end

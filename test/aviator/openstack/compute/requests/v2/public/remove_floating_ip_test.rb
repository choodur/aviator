require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/public/remove_floating_ip' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:server_id] = 'randompassword'
                  params[:address]   = '0.0.0.0'
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
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'public', 'remove_floating_ip.rb')
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
      klass.required_params.must_equal [:server_id, :address]
    end


    validate_attr :url do
      session_data = get_session_data
      compute_url  = session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['publicURL']
      server_id    = 'dummyID'
      url          = "#{ compute_url }/servers/#{ server_id }/action"

      request = create_request do |params|
        params[:server_id]  = server_id
        params[:address]    = '0.0.0.1'
      end

      request.url.must_equal url
    end


    validate_response 'valid parameters are provided' do
      fip        = helper.create_floating_ip(session).body[:floating_ip]
      server     = helper.create_server(session).body[:server]
      ip_address = fip[:ip]

      session.compute_service.request :add_floating_ip, :api_version => :v2 do |params|
        params[:server_id]  = server[:id]
        params[:address]    = ip_address
      end

      response = session.compute_service.request :remove_floating_ip, :api_version => :v2 do |params|
        params[:server_id]  = server[:id]
        params[:address]    = ip_address
      end

      server_get_response = session.compute_service.request :get_server, :api_version => :v2 do |p|
        p[:id] = server[:id]
      end

      get_body = server_get_response.body

      response.status.must_equal 202
      response.headers.wont_be_nil

      server_get_response.status.must_equal 200
      get_body.wont_be_nil
      get_body[:server][:addresses][:private]
          .map{|a| a[:addr] == ip_address && a["OS-EXT-IPS:type"] == "floating"}.wont_include true

      helper.delete_floating_ip(session, fip[:id])
      helper.delete_server(session, server[:id])
    end


    validate_response 'non existent server is provided' do
      fip        = helper.create_floating_ip(session).body[:floating_ip]
      ip_address = fip[:ip]
      server_id  = 'server1doesntexist'

      response = session.compute_service.request :remove_floating_ip, :api_version => :v2 do |params|
        params[:server_id]  = server_id
        params[:address]    = ip_address
      end

      response.status.must_equal 422
      response.headers.wont_be_nil
      response.body["computeFault"].wont_be_nil
      response.body["computeFault"]["message"].must_equal "Floating ip #{ ip_address } is not associated with instance #{ server_id }."

      helper.delete_floating_ip(session, fip[:id])
    end


    validate_response 'non existent IP address is provided' do
      server = helper.create_server(session).body[:server]

      response = session.compute_service.request :remove_floating_ip, :api_version => :v2 do |params|
        params[:server_id]  = server[:id]
        params[:address]    = '0.0.0.1.95.9'
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
      response.body["itemNotFound"].wont_be_nil
      response.body["itemNotFound"]["message"].must_equal "floating ip not found"

      helper.delete_server(session, server[:id])
    end


  end

end

require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/public/create_floating_ip' do

    def create_request(session_data = get_session_data, &block)
      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_response
    end


    def helper
      Aviator::Test::OpenstackHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'public', 'create_floating_ip.rb')
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
      klass.optional_params.must_equal [:pool]
    end


    validate_attr :required_params do
      klass.required_params.must_equal []
    end


    validate_attr :url do
      session_data = get_session_data
      compute_url  = session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['publicURL']
      url          = "#{ compute_url }/os-floating-ips"
      request      = klass.new(session_data)

      request.url.must_equal url
    end


    validate_response 'no parameter is provided' do
      response = session.compute_service.request :create_floating_ip, :api_version => :v2

      response.status.must_equal 200
      response.headers.wont_be_nil
      response.body[:floating_ip][:pool].must_equal "public"
      helper.delete_floating_ip(session, response.body[:floating_ip][:id])
    end


    validate_response 'pool with no more floating IPs is provided' do
      response = session.compute_service.request :create_floating_ip, :api_version => :v2 do |params|
        params[:pool] = "nova"
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
    end

  end

end

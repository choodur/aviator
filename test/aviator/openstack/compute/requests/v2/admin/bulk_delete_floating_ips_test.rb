require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/admin/bulk_delete_floating_ips' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |p|
        p[:ip_range] = '192.168.6.56/29'
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
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'admin', 'bulk_delete_floating_ips.rb')
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


    validate_attr :body do
      klass.body?.must_equal true
      create_request.body?.must_equal true
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :admin
    end


    validate_attr :headers do
      session_data = get_session_data

      headers = { 'X-Auth-Token' => session_data[:body][:access][:token][:id] }

      request = create_request(session_data)

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :put
    end


    validate_attr :url do
      compute_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['adminURL']
      url         = "#{ compute_url }/os-floating-ips-bulk/delete"
      request     = create_request

      request.url.must_equal url
    end


    validate_response 'valid parameters are provided' do
      response = session.compute_service.request :bulk_delete_floating_ips, :api_version => :v2 do |params|
        params[:ip_range] = '192.168.7.56/29'
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:floating_ips_bulk_delete].wont_be_nil
      response.headers.wont_be_nil
    end

    validate_response 'invalid parameters are provided' do
      response = session.compute_service.request :bulk_delete_floating_ips, :api_version => :v2 do |params|
        params[:ip_range]  = 'this-is-invalid!'
      end

      response.status.must_equal 400
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end

  end

end
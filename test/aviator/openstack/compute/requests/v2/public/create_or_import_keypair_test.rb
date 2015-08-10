require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/requests/v2/public/create_or_import_keypair' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:name] = "keypair name"
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
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'public', 'create_or_import_keypair.rb')
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
      klass.optional_params.must_equal [:public_key]
    end

    validate_attr :required_params do
      klass.required_params.must_equal [:name]
    end

    validate_attr :url do
      compute_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'compute' }[:endpoints][0]['publicURL']
      url         = "#{ compute_url }/os-keypairs"

      request = create_request

      request.url.must_equal url
    end

    validate_response 'valid parameters are provided' do
      response = session.compute_service.request :create_or_import_keypair do |params|
        params[:name]       = "keypair name"
        params[:public_key] = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDx8nkQv/zgGgB4rMYmIf+6A4l6Rr+o/6lHBQdW5aYd44bd8JttDCE/F/pNRr0lRE+PiqSPO8nDPHw0010JeMH9gYgnnFlyY3/OcJ02RhIPyyxYpv9FhY+2YiUkpwFOcLImyrxEsYXpD/0d3ac30bNH6Sw9JD9UZHYcpSxsIbECHw== Generated by Nova"
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:keypair].length.wont_equal 0
      response.body[:keypair][:fingerprint].wont_be_nil
      response.headers.wont_be_nil
    end
  end
end

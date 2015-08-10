require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/image/requests/v1/public/update_image_status' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:id] = 'image-id'
                  params[:status] = 'status'
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
      @klass ||= helper.load_request('openstack', 'image', 'v1', 'public', 'update_image_status.rb')
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

      klass.body?.must_equal false
      request.body?.must_equal false
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :public
    end


    validate_attr :headers do
      headers = {
        'X-Auth-Token'                  => get_session_data[:body][:access][:token][:id],
        'x-image-meta-status'           => 'status',
        'x-glance-registry-purge-props' => 'False'
      }

      request = create_request

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :put
    end

    validate_attr :required_params do
      klass.required_params.must_equal [:id, :status]
    end


    validate_attr :url do
      image_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'image' }[:endpoints][0]['publicURL']
      image_id  = "some-image-id"
      url       = "#{ image_url }/v1/images/#{ image_id }"

      request = klass.new(get_session_data) do |p|
        p[:id] = image_id
        p[:status] = 'active'
      end

      request.url.must_equal url
    end

    validate_response 'valid params are provided' do
      response = session.image_service.request(:create_image)
      os_image = response.body[:image]

      os_image[:status].must_equal 'queued'

      response = session.image_service.request :update_image_status do |params|
        params[:id] = os_image[:id]
        params[:status] = 'active'
      end

      response.status.must_equal 200
      response.headers.wont_be_nil
      response.body.wont_be_nil
      response.body[:image].wont_be_nil
      response.body[:image][:status].must_equal 'active'

      details_response = session.compute_service.request :get_image_details do |params|
        params[:id] = os_image[:id]
      end

      details_response.status.must_equal 200
      details_response.headers.wont_be_nil
      details_response.body.wont_be_nil
      details_response.body[:image][:status].downcase.must_equal 'active'

      session.compute_service.request(:delete_image) do |params|
        params.id = os_image[:id]
      end
    end

    validate_response 'invalid status is provided' do
      response = session.image_service.request(:create_image)
      os_image = response.body[:image]

      os_image[:status].must_equal 'queued'

      response = session.image_service.request :update_image_status do |params|
        params[:id] = os_image[:id]
        params[:status] = 'bogus-status'
      end

      response.status.must_equal 400

      details_response = session.compute_service.request :get_image_details do |params|
        params[:id] = os_image[:id]
      end

      details_response.status.must_equal 200
      details_response.headers.wont_be_nil
      details_response.body.wont_be_nil
      details_response.body[:image][:status].wont_equal 'bogus-status'

      session.compute_service.request(:delete_image) do |params|
        params.id = os_image[:id]
      end
    end

    validate_response 'invalid id parameter is provided' do
      response = session.image_service.request(:update_image_status) do |params|
        params[:id] = 'bogus-nonexistent-id'
        params[:status] = 'queued'
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
    end
  end

end

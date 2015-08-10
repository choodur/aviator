require 'test_helper'
require 'open-uri'

class Aviator::Test

  describe 'aviator/openstack/image/requests/v2/public/create_image' do

    def create_request(session_data = get_session_data)
      klass.new(session_data)
    end


    def get_session_data
      session.send :auth_response
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'image', 'v2', 'public', 'create_image.rb')
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
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :public
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :post
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal [
        :name,
        :id,
        :visibility,
        :tags,
        :container_format,
        :disk_format,
        :min_disk,
        :min_ram,
        :protected,
        :properties
      ]
    end


    validate_attr :required_params do
      klass.required_params.must_equal []
    end


    validate_attr :url do
      image_url = get_session_data[:body][:access][:serviceCatalog].find { |s| s[:type] == 'image' }[:endpoints][0]['publicURL']
      url       = "#{ image_url }/v2/images"

      create_request.url.must_equal url
    end

    validate_response 'valid params are provided' do
      response = session.image_service.request :create_image, :api_version => :v2 do |params|
        params[:name]             = 'CirrOS'
        params[:disk_format]      = 'ari'
        params[:container_format] = 'ari'
      end

      response.status.must_equal 201
      response.headers.wont_be_nil
    end

    validate_response 'no parameters are provided' do
      images          = session.image_service.request(:list_images, :api_version => :v2).body[:images]
      response        = session.image_service.request(:create_image, :api_version => :v2)
      updated_images  = session.image_service.request(:list_images, :api_version => :v2).body[:images]

      response.status.must_equal 400
    end

    validate_response 'invalid disk format is provided' do
      response = session.image_service.request :create_image, :api_version => :v2 do |params|
        params[:name]         = 'test image'
        params[:disk_format]  = 'xxx'
      end

      response.status.must_equal 400
      response.headers.wont_be_nil
    end

    validate_response 'invalid container format is provided' do
      response = session.image_service.request :create_image, :api_version => :v2 do |params|
        params[:name]             = 'test image'
        params[:container_format] = 'xxx'
      end

      response.status.must_equal 400
      response.headers.wont_be_nil
    end

    validate_response 'existing image id is provided' do
      image_id = session.image_service.request(:list_images, :api_version => :v2).body[:images][0][:id]

      response = session.image_service.request :create_image, :api_version => :v2 do |params|
        params[:name] = 'test image'
        params[:id]   = image_id
      end

      response.status.must_equal 500
      response.headers.wont_be_nil
    end

  end

end

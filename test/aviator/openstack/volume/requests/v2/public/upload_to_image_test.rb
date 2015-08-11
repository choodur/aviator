require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/requests/v2/public/upload_to_image' do

    def get_session_data
      session.send :auth_response
    end

    def helper
      Aviator::Test::OpenstackHelper
    end

    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'public', 'upload_to_image.rb')
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

    validate_response 'parameters are provided' do
      volume = helper.create_volume(session).body[:volume]
      image_name = 'upload-to-image-test'

      response = session.volume_service.request(:upload_to_image, :api_version => :v2) do |p|
        p.volume_id  = volume[:id]
        p.image_name = image_name
        p.force      = 'True'
      end

      response.status.must_equal 202

      os_image = response.body['os-volume_upload_image']
      os_image['image_id'].wont_be_empty
      os_image['image_name'].must_equal image_name

      sleep 10 if VCR.current_cassette.recording?
      session.compute_service.request(:delete_image, :api_version => :v2) { |p| p.id = os_image['image_id'] }
      helper.delete_volume(session, volume[:id])
    end

  end

end

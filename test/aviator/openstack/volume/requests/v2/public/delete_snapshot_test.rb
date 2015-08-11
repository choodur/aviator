require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/requests/v2/public/delete_snapshot' do

    def get_session_data
      session.send :auth_response
    end

    def helper
      Aviator::Test::OpenstackHelper
    end

    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'public', 'delete_snapshot.rb')
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
      volume   = helper.create_volume(session).body[:volume]
      snapshot = helper.create_volume_snapshot(session, volume[:id]).body[:snapshot]

      response = session.volume_service.request(:delete_snapshot, :api_version => :v2) do |params|
        params[:snapshot_id] = snapshot[:id]
      end

      response.status.must_equal 202

      sleep 5 if VCR.current_cassette.recording?

      list = session.volume_service.request(:list_snapshots, :api_version => :v2)
      list.body[:snapshots].collect{ |s| s[:id] }.include?(snapshot[:id]).must_equal false

      helper.delete_volume(session, volume[:id])
    end

  end

end

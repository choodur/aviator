
require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/volume/requests/v2/public/update_snapshot' do

    def get_session_data
      session.send :auth_response
    end

    def helper
      Aviator::Test::OpenstackHelper
    end

    def klass
      @klass ||= helper.load_request('openstack', 'volume', 'v2', 'public', 'update_snapshot.rb')
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
      snapshot_name = 'Updated Snapshot Name'

      response = session.volume_service.request(:update_snapshot, :api_version => :v2) do |params|
        params[:snapshot_id] = snapshot[:id]
        params[:name] = snapshot_name
      end

      response.status.must_equal 200
      response.body[:snapshot].wont_be_nil
      response.body[:snapshot][:name].must_equal snapshot_name

      helper.delete_volume_snapshot(session, snapshot[:id])
      helper.delete_volume(session, volume[:id])
    end

  end

end

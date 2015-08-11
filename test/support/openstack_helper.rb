require_relative 'request_helper'
require 'forwardable'

module Aviator
  class Test
    module OpenstackHelper
      extend SingleForwardable

      single_delegate [:admin_session_data, :admin_bootstrap_session_data,
        :get_request_class, :load_request, :request_path] => :request_helper

      class << self
        def request_helper
          @request_helper ||= Aviator::Test::RequestHelper
        end

        def create_floating_ip(session)
          session.compute_service.request :create_floating_ip, :api_version => :v2
        end

        def create_security_group(session)
          session.compute_service.request :create_security_group, :api_version => :v2 do |params|
            params[:name]         = 'Aviator Security Group'
            params[:description]  = 'Aviator Security Group'
          end
        end

        def create_server(session)
          nova      = session.compute_service
          image_id  = nova.request(:list_images, :api_version => :v2).body[:images].first[:id]
          flavor_id = nova.request(:list_flavors, :api_version => :v2).body[:flavors].first[:id]

          response = nova.request :create_server, :api_version => :v2 do |params|
            params[:imageRef]  = image_id
            params[:flavorRef] = flavor_id
            params[:name]      = 'Aviator Server'
          end

          sleep 10 if VCR.current_cassette.recording?

          response
        end

        def create_volume(session)
          response = session.volume_service.request :create_volume, :api_version => :v1 do |params|
            params[:display_name]         = 'Aviator Volume Test Name'
            params[:display_description]  = 'Aviator Volume Test Description'
            params[:size]                 = '1'
          end

          sleep 10 if VCR.current_cassette.recording?

          response
        end

        def create_volume_snapshot(session, volume_id)
          response = session.volume_service.request(:create_snapshot, :api_version => :v2) do |params|
            params[:name]         = 'Aviator Volume Snapshot Name'
            params[:description]  = 'Aviator Volume Snapshot Description'
            params[:volume_id]    =  volume_id
            params[:force]        =  true
          end

          sleep 5 if VCR.current_cassette.recording?

          response
        end

        def delete_floating_ip(session, id)
          session.compute_service.request(:delete_floating_ip, :api_version => :v2, :params => { :id => id })
        end

        def delete_keypair(session, name)
          session.compute_service.request(:delete_keypair, :api_version => :v2, :params => { :keypair_name => name })
        end

        def delete_security_group(session, id)
          session.compute_service.request(:delete_security_group, :api_version => :v2, :params => { :id => id })
        end

        def delete_server(session, id)
          response = session.compute_service.request(:delete_server, :api_version => :v2, :params => { :id => id })
          sleep 10 if VCR.current_cassette.recording?
          response
        end

        def delete_volume(session, id)
          response = session.volume_service.request(:delete_volume, :api_version => :v1, :params => { :id => id })
          sleep 10 if VCR.current_cassette.recording?
          response
        end

        def delete_volume_snapshot(session, id)
          response = session.volume_service.request(:delete_snapshot, :api_version => :v2, :params => { :id => id })
          sleep 5 if VCR.current_cassette.recording?
          response
        end

        def get_project(session, project)
          session.identity_service
                 .request(:list_tenants, :api_version => :v2)
                 .body[:tenants]
                 .find { |t| t[:name] == project }
        end

        def get_security_group(session, id)
          session.compute_service.request(:get_security_group, :api_version => :v2, :params => { :id => id })
        end

        def get_user(session, user)
          session.identity_service
                 .request(:list_users, :api_version => :v2)
                 .body[:users]
                 .find { |u| u[:name] == user }
        end
      end
    end
  end
end

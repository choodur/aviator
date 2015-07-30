module Aviator

  define_request :delete_volume_type, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service,     :volume
    meta :api_version, :v2

    link 'documentation', 'http://developer.openstack.org/api-ref-blockstorage-v2.html#volume-api-v2-types'

    param :id, required: true

    def headers
      super
    end

    def http_method
      :delete
    end

    def url
      "#{ base_url }/types/#{ params[:id] }"
    end
  end

end

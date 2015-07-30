module Aviator

  define_request :list_volume_types, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :provider,       :openstack
    meta :service,        :volume
    meta :api_version,    :v2
    meta :endpoint_type,  :public

    link 'documentation', 'http://developer.openstack.org/api-ref-blockstorage-v2.html#volume-api-v2-types'

    def headers
      super
    end

    def http_method
      :get
    end

    def url
      "#{ base_url }/types"
    end

  end

end

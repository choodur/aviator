module Aviator

  define_request :create_volume_type, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service,     :volume
    meta :api_version, :v2

    link 'documentation', 'http://developer.openstack.org/api-ref-blockstorage-v2.html#volume-api-v2-types'

    param :name,        required: true
    param :extra_specs, required: false

    def body
      p = {
        volume_type: {
          name: params[:name]
        }
      }

      optional_params.each do |key|
        p[:volume_type][key] = params[key] if params[key]
      end

      p
    end

    def headers
      super
    end

    def http_method
      :post
    end

    def url
      "#{ base_url }/types"
    end
  end

end

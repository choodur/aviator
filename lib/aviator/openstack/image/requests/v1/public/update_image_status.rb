module Aviator

  define_request :update_image_status, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service,      :image
    meta :api_version,  :v1

    link 'documentation', 'http://developer.openstack.org/api-ref-image-v1.html#updateImage-v1'

    param :id,     required: true
    param :status, required: true

    def headers
      h = {
        'X-Auth-Token'                  => session_data.token,
        'x-image-meta-status'           => params[:status],
        'x-glance-registry-purge-props' => 'False'
      }

      h.reject { |k,v| v.nil? }
    end

    def http_method
      :put
    end

    def url
      "#{ base_url}/images/#{ params[:id] }"
    end

  end

end

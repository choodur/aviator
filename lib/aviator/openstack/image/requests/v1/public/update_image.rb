module Aviator

  define_request :update_image, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service,      :image
    meta :api_version,  :v1

    link 'documentation', 'http://developer.openstack.org/api-ref-image-v1.html#updateImage-v1'

    param :id,                required: true
    param :name,              required: false
    param :disk_format,       required: false
    param :container_format,  required: false
    param :owner,             required: false
    param :min_ram,           required: false
    param :min_disk,          required: false
    param :checksum,          required: false
    param :is_public,         required: false
    param :is_protected,      required: false
    param :properties,        required: false
    param :location,          required: false

    def headers
      h = {
        'X-Auth-Token'                  => session_data[:body][:access][:token][:id],
        'x-image-meta-name'             => params[:name],
        'x-image-meta-disk-format'      => params[:disk_format],
        'x-image-meta-container-format' => params[:container_format],
        'x-image-meta-owner'            => params[:owner],
        'x-image-meta-min-ram'          => params[:min_ram],
        'x-image-meta-min-disk'         => params[:min_disk],
        'x-image-meta-checksum'         => params[:checksum],
        'x-image-meta-is-public'        => params[:is_public],
        'x-image-meta-protected'        => params[:is_protected],
        'x-image-meta-location'         => params[:location],
      }

      unless params[:properties].nil?
        params[:properties].each { |k, v| h["x-image-meta-property-#{k}"] = v }
      end

      h.reject { |k,v| v.nil? }
    end

    def http_method
      :put
    end

    def url
      "#{ base_url }/v1/images/#{ params[:id] }"
    end

  end

end

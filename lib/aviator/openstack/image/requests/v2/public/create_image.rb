module Aviator

  define_request :create_image, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service, :image
    meta :api_version, :v2

    link 'documentation', 'http://developer.openstack.org/api-ref-image-v2.html#images-v2'

    param :name,              required: false
    param :id,                required: false
    param :visibility,        required: false
    param :tags,              required: false
    param :container_format,  required: false
    param :disk_format,       required: false
    param :min_disk,          required: false
    param :min_ram,           required: false
    param :protected,         required: false
    param :properties,        required: false

    def body
      p = {}

      keys = optional_params.reject { |p| p == :properties }

      keys.each do |key|
        p[key] = params[key] if params[key]
      end

      unless params[:properties].nil?
        params[:properties].each do |key, value|
          p[key] = value unless value.nil?
        end
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
      "#{ base_url }/v2/images"
    end

  end

end

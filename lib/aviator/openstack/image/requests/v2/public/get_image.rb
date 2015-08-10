module Aviator

  define_request :get_image, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service, :image

    link 'documentation', 'http://docs.openstack.org/api/openstack-image-service/2.0/content/get-an-image.html'

    param :image_id, required: true, alias: :id

    def headers
      super
    end

    def http_method
      :get
    end

    def url
      "#{ base_url }/v2/images/#{ params[:image_id] }"
    end

  end

end

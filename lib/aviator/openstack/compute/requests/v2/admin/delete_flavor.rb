module Aviator
  
  define_request :delete_flavor, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service, :compute

    link 'documentation',
         'http://developer.openstack.org/api-ref-compute-v2-ext.html#ext-os-flavormanage'

    param :flavor_id, required: true


    def headers
      super
    end


    def http_method
      :delete
    end


    def url
      "#{ base_url }/flavors/#{ params[:flavor_id]}"
    end

  end

end
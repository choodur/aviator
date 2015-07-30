module Aviator

  define_request :remove_flavor_from_project, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service, :compute

    link 'documentation',
         'http://developer.openstack.org/api-ref-compute-v2-ext.html#ext-os-flavor-access'

    param :flavor_id,          required: true
    param :tenant,             required: true


    def headers
      super
    end

    def body
      p = {
        :'removeTenantAccess' => {
          :'tenant' => params[:tenant]
        }
      }
    end

    # Documented (see above link) as :delete yet using :post
    def http_method
      :post
    end


    def url
      "#{ base_url }/flavors/#{ params[:flavor_id] }/action"
    end

  end

end
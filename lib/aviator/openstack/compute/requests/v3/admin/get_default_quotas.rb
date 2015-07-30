module Aviator

  define_request :get_default_quotas, inherit: [:openstack, :common, :v3, :admin, :base] do

    meta :service,      :compute

    link 'documentation',
      'http://api.openstack.org/api-ref-compute-v3.html#v3quotasets'

    param :tenant_id, required: true


    def headers
      super
    end


    def http_method
      :get
    end


    def url
      "#{ base_url }/os-quota-sets/#{ params[:tenant_id] }/defaults"
    end

  end

end

module Aviator

  define_request :get_quotas, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service,      :compute
    meta :api_version,  :v3

    link 'documentation',
      'http://api.openstack.org/api-ref-compute-v3.html#v3quotasets'

    link 'documentation',
      'https://bugs.launchpad.net/nova/+bug/1183870'

    param :tenant_id, required: true
    param :detail,    required: false


    def headers
      super
    end


    def http_method
      :get
    end


    def url
      str = "#{ base_url }/os-quota-sets/#{ params[:tenant_id] }"
      str += "/detail" if params[:detail]
      str
    end

  end

end

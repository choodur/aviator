module Aviator

  define_request :update_quotas, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service,      :volume
    meta :api_version,  :v2

    link 'documentation',
      'http://docs.openstack.org/trunk/openstack-ops/content/projects_users.html'
    link 'documentation',
      'https://github.com/openstack/python-cinderclient/blob/master/cinderclient/v2/quotas.py'

    param :tenant_id,     required: true
    param :gigabytes,     required: false
    param :snapshots,     required: false
    param :volumes,       required: false
    param :custom_quotas, required: false


    def body
      p = {
        quota_set: {}
      }

      defaults = optional_params - [:custom_quotas]

      defaults.each do |attr|
        p[:quota_set][attr] = params[attr].to_i if params[attr]
      end

      unless params[:custom_quotas].nil?
        params[:custom_quotas].each do |quota, limit|
          p[:quota_set][quota] = limit.to_i if limit
        end
      end

      p
    end


    def headers
      super
    end


    def http_method
      :put
    end


    def url
      "#{ base_url }/os-quota-sets/#{ params[:tenant_id] }"
    end

  end

end

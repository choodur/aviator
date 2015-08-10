module Aviator

  define_request :list_user_roles_on_tenant, inherit: [:openstack, :common, :v2, :admin, :base] do

    meta :service, :identity

    link 'documentation',
      'http://api.openstack.org/api-ref-identity.html#identity-admin-v2'

    param :tenant_id, required: true
    param :user_id, required: true

    def headers
      h = {}

      unless self.anonymous?
        h['X-Auth-Token'] = session_data[:body][:access][:token][:id]
      end

      h
    end


    def http_method
      :get
    end


    def url
      "#{ base_url }/tenants/#{ params[:tenant_id] }/users/#{ params[:user_id] }/roles"
    end

  end

end

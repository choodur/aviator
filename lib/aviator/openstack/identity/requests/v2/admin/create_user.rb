module Aviator

  define_request :create_user, :inherit => [:openstack, :common, :v2, :admin, :base] do

    meta :service, :identity


    link 'documentation',
      'http://docs.openstack.org/api/openstack-identity-service/2.0/content/POST_addUser_v2.0_users_.html'

    link 'documentation bug',
      'https://bugs.launchpad.net/keystone/+bug/1110435'

    link 'documentation bug',
      'https://bugs.launchpad.net/keystone/+bug/1226466'


    param :name,      :required => true
    param :password,  :required => true

    param :email,     :required => false
    param :enabled,   :required => false
    param :tenantId,  :required => false, :alias => :tenant_id
    param :extras,    :required => false


    def body
      p = {
        :user => {}
      }

      (required_params + optional_params).each do |key|
        p[:user][key] = params[key] if params[key]
      end

      p
    end


    def headers
      h = {}

      unless self.anonymous?
        h['X-Auth-Token'] = session_data[:body][:access][:token][:id]
      end

      h
    end


    def http_method
      :post
    end


    def url
      "#{ base_url }/users"
    end

  end

end

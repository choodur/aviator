module Aviator

  define_request :list_roles, :inherit => [:openstack, :common, :v2, :admin, :base] do

    meta :service, :identity

    link 'documentation',
      'http://api.openstack.org/api-ref-identity.html#os-ksadm-admin-ext'


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
      "#{ base_url }/OS-KSADM/roles/"
    end

  end

end

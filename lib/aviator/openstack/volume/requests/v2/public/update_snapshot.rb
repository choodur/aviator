module Aviator

  define_request :update_snapshot, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service,        :volume
    meta :api_version,    :v2

    link 'documentation', 'http://docs.openstack.org/api/openstack-block-storage/2.0/content/PUT_updateSnapshot__v2__tenant_id__snapshots__snapshot_id__Snapshots.html'

    param :snapshot_id,         required: true, alias: :id
    param :name,        required: false
    param :description, required: false

    def body
      p = {
        snapshot: {}
      }

      optional_params.each do |key|
        p[:snapshot][key] = params[key] if params[key]
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
      "#{ base_url }/snapshots/#{ params[:snapshot_id] }"
    end
  end

end

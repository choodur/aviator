module Aviator

  define_request :upload_to_image, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service,     :volume
    meta :api_version, :v2

    link 'documentation', 'https://wiki.openstack.org/wiki/CreateVolumeFromImage'

    param :volume_id,        required: true
    param :image_name,       required: true
    param :force,            required: false # <'True' | 'False'>
    param :container_format, required: false
    param :disk_format,      required: false


    def body
      p = {
        'os-volume_upload_image' => { image_name: params[:image_name] }
      }

      optional_params.each do |key|
        p['os-volume_upload_image'][key] = params[key] if !key.nil? && key.size > 0
      end

      p['os-volume_upload_image'][:container_format] ||= 'bare'
      p['os-volume_upload_image'][:disk_format]      ||= 'raw'

      p
    end

    def headers
      super
    end

    def http_method
      :post
    end

    def url
      "#{ base_url }/volumes/#{ params[:volume_id] }/action"
    end

  end

end


require('aurita')
# require('RMagick') # Require manually in dispatch runner if needed (big lib!)
Aurita.import_plugin_module :wiki, :media_asset_helpers

module Aurita
module Plugins
module Wiki

  class Media_Asset_Renderer
  include Media_Asset_Helpers

    def initialize(media_asset_id)
      @media_asset_id = media_asset_id
    end

    def render(params={})
      image_file_path = Aurita.project.base_path+'public/assets/asset_' << @media_asset_id + '.jpg'
      image = Magick::ImageList.new(image_file_path)
      image = image.resize_to_fit(params[:x],params[:y]) if params[:x] && params[:y]
      puts image.to_blob
    end

  end

end
end
end

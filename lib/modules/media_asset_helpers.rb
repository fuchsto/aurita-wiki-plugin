
module Aurita
module Plugins
module Wiki

  module Media_Asset_Helpers
    
    def temp_filename_for(media_asset_id)
      Aurita.project_path + 'public/assets/tmp/asset_' << media_asset_id + '.jpg'
    end
    
  end

end
end
end



require('aurita/controller')
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_folder

module Aurita
module Plugins
module Wiki

  class User_Media_Asset_Folder_Controller < Plugin_Controller

    def perform_add
      @params[:user_group_id] = Aurita.user.user_group_id
      super()
    end

    def perform_delete
      @params[:user_group_id] = Aurita.user.user_group_id
      super()
    end

    def perform_update
      @params[:user_group_id] = Aurita.user.user_group_id
      super()
    end

    def select_image
      images = Media_Asset.all_with((Media_Asset.media_folder_id == param(:media_asset_folder_id)) &
                                    (Media_Asset.deleted == 'f') & 
                                    (Media_Asset.mime.ilike('image/%'))).entities
      decorator = Proc.new { |e, element|
        element[0].onclick = "Aurita.Wiki.select_media_asset_click('#{e.media_asset_id}', '#{param(:image_dom_id)}');"
        element[0].add_css_class(:link)
        log { element } 
        element
      }
      grid = GUI::Media_Asset_Grid.new(images, :thumbnail_size => :tiny, :decorator => decorator)

      return grid
    end

  end

end
end
end



require('aurita')
require('aurita-gui')
Aurita.import_plugin_module :wiki, 'gui/media_asset_folder_thumbnail'

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_Folder_Grid < Aurita::GUI::Widget
  include Aurita::GUI::Link_Helpers

    def initialize(entities, params={})
      @entities         = entities
      super()
    end

    def element
      HTML.div.media_asset_folder_grid { 
        @entities.map { |e| 
          folder = Media_Asset_Folder_Thumbnail.new(e, :size => @thumbnail_size)
          folder[0].onclick = link_to(e, :action => :show_grid) 
          folder[0].add_css_class(:link)
          Context_Menu_Element.new(folder, e) 
        }
      }
    end

  end

end
end
end
end


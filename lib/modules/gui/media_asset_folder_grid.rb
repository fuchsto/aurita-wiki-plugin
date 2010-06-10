
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
          folder[0].onclick = "#{link_to(e, :action => :show_grid)} return false;"
          folder[0].href    = "/aurita/#{resource_url_for(e, :action => :show_grid)}"
          Context_Menu_Element.new(e, :show_button => :prepend) { folder }
        }
      }
    end

  end

end
end
end
end


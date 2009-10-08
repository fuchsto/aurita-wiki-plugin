
require('aurita')
require('aurita-gui')
require('aurita-gui/widget')

module Aurita
module Plugins
module Wiki
module GUI
 
  class Media_Asset_Folder_Thumbnail < Aurita::GUI::Widget
  include Aurita::GUI::I18N_Helpers
  include Aurita::GUI::Link_Helpers

    def initialize(entity, params={})
      @entity = entity
      super()
    end

    def element
      if @entity.num_files > 0 then
        info = HTML.div.num_files { "#{@entity.num_files} #{tl(:files)}" } + 
               HTML.div.total_size { @entity.total_size.filesize }
      else
        info = HTML.div.num_files { tl(:folder_is_empty) }
      end
      HTML.div(:class => [ :media_asset_thumbnail, :bright_bg ]) { 
        HTML.div.image { 
          HTML.img(:src => '/aurita/images/icons/folder_medium.gif', 
                   :alt => @entity.physical_path,
                   :title => @entity.physical_path) 
        } +
        HTML.div(:class => [:info, :default_bg]) { 
          HTML.div.title { link_to(@entity) { @entity.physical_path } } + info
        }
      }
    end

  end

end
end
end
end

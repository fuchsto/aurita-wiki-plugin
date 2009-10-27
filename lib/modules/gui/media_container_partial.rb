
require('aurita')
require('aurita-gui')
require('aurita-gui/html')
require('aurita-gui/element')
require('aurita-gui/widget')

Aurita.import_module :gui, :link_helpers
Aurita.import_plugin_module :wiki, 'gui/media_asset_thumbnail'

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Container_Partial < Aurita::GUI::Widget
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers

    def initialize(media_container, params={})
      @media_container = media_container
      super()
    end

    def element

      HTML.div.media_container_partial { 
        HTML.div.images { 
          @media_container.media_assets(Media_Asset.mime.ilike('image/%')).map { |image|
            entry = HTML.div.image_partial { 
              link_to(image) { GUI::Media_Asset_Thumbnail.new(image, :size => :preview).string }
            }
            Context_Menu_Element.new(entry, :entity => image) 
          }
        } + HTML.div(:style => 'clear: both;') + 
        HTML.div.files { 
          @media_container.media_assets(Media_Asset.mime.not_ilike('image/%')).map { |file|
            entry = HTML.div.file_partial { 
              link_to(file) { GUI::Media_Asset_Thumbnail.new(file, :size => :tiny).string }
            }
            link_to(file) { Context_Menu_Element.new(entry, :entity => file).string } 
          }
        } + HTML.div(:style => 'clear: both;') 
      }
    end

  end

end
end
end
end


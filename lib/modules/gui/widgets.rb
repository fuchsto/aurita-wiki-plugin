
require('aurita')
require('aurita-gui/html')
require('aurita-gui/widget')

Aurita.import_plugin_module :wiki, 'gui/media_asset_table'

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_Thumbnail_Decorator < Aurita::GUI::Widget
  include Aurita::GUI

    attr_accessor :asset

    def initialize(asset, params={})
      params[:class] = :media_asset_thumbnail_decorator unless params[:class]
      @attrib = params
      @asset  = asset
      super()
    end
    def element
      HTML.div.media_asset_thumbnail(@attrib) { 
        HTML.div.icon { asset.icon } + 
        HTML.div.info { 
          HTML.div.filename { asset.physical_path } +
          HTML.div.tags { asset.tags } +
          HTML.div.description { asset.description } 
        }
      }
    end
  end

end
end
end
end


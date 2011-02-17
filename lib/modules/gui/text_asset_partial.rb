
require('aurita')
require('aurita/base/plugin_methods')

module Aurita
module Plugins
module Wiki
module GUI

  class Text_Asset_Partial < Aurita::GUI::Widget
    include Aurita::Plugin_Methods

    attr_accessor :text_asset
    
    def initialize(text_asset)
      @text_asset = text_asset
      super()
    end
    
    def element

      text = @text_asset.display_text
      
      filters = plugin_get(Hook.wiki.text_asset.text_filter)
      filters.each { |f|
        text = f.call(text)
      }
      
      HTML.div(:class => :text_asset_partial, 
               :id    => "text_asset_#{@text_asset.text_asset_id}") { 
        text
      }
    end

  end

end
end
end
end


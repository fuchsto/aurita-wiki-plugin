
module Aurita
module Plugins
module Wiki
module GUI

  class Text_Asset_Partial < Aurita::GUI::Widget

    attr_accessor :text_asset
    
    def initialize(text_asset)
      @text_asset = text_asset
      super()
    end
    
    def element
      HTML.div(:class => :text_asset_partial, 
               :id    => "text_asset_#{@text_asset.text_asset_id}") { 
        @text_asset.display_text 
      }
    end

  end

end
end
end
end


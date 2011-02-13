
module Aurita
module Plugins
module Wiki
module GUI

  class Text_Asset_Dump_Partial < Aurita::GUI::Widget
    
    def initialize(part)
      @text = part[:dump]
      super()
    end
    
    def element
      HTML.div.article_text { 
        HTML.div.article_contextual_partial { 
          HTML.div.text_asset_partial { 
            @text
          }
        }
      }
    end

  end

end
end
end
end


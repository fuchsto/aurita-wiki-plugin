
module Aurita
module Plugins
module Wiki
module GUI

  class Media_Container_Dump_Partial < Aurita::GUI::Widget
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers
    
    def initialize(part)
      @part = part
      @media_container = Media_Container.get(part[:media_container_id])
      @media_asset_ids = @part[:dump]
      super()
    end
    
    def element
      # Preserve order by mapping 
      media_assets = @media_asset_ids.map { |m|
        Media_Asset.get(m)
      }
      images = []
      files  = []

      media_assets.each { |m|
        if m.is_image? then
          images << m
        else
          files << m
        end
      }

      HTML.div.media_container_partial { 
        HTML.div.images { 
          images.map { |image|
            entry = HTML.div.image_partial { 
              link_to(image) { GUI::Media_Asset_Thumbnail.new(image, :size => :preview).string }
            }
            Context_Menu_Element.new(entry, :entity => image) 
          }
        } + 
        HTML.div(:style => 'clear: both;') + 
        HTML.div.files { 
          files.map { |file|
            entry = HTML.div.file_partial { 
              link_to(file) { GUI::Media_Asset_Thumbnail.new(file, :size => :tiny).string }
            }
            link_to(file) { Context_Menu_Element.new(entry, :entity => file).string } + 
            HTML.div.file_partial_separator { } 
          }
        } + 
        HTML.div(:style => 'clear: both;') 
      }
    end

  end

end
end
end
end


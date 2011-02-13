
module Aurita
module Plugins
module Wiki
module GUI

  class Media_Container_Dump_Partial < Aurita::GUI::Widget
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers
    
    def initialize(part)
      @dump = part[:dump]
      @media_container = Media_Container.get(@dump[:media_container_id])
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
        } + 
        HTML.div(:style => 'clear: both;') + 
        HTML.div.files { 
          @media_container.media_assets(Media_Asset.mime.not_ilike('image/%')).map { |file|
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


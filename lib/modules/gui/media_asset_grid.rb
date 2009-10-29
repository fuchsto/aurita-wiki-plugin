
require('aurita')
require('aurita-gui')
Aurita.import_plugin_module :wiki, 'gui/media_asset_thumbnail'

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_Grid < Aurita::GUI::Widget
  include Aurita::GUI::Link_Helpers

    # Expects Array of Media_Asset instances. 
    # Optional parameters are 
    #
    # [:thumbnail_size] : Image size to use for thumbnails, like :tiny, :thumb, :small etc. 
    # [:decorator] : Proc to use for decorating thumbnails. Yields Media_Asset instance and its
    #                Element to be decorated. 
    #i0 Example: 
    #
    #   dec = Proc.new { |media_asset, element| 
    #     Context_Menu_Element.new(element, :entity => media_asset) 
    #   }
    #   grid = Media_Asset_Grid.new(images, :decorator => dec)
    #
    def initialize(entities, params={})
      @entities         = entities
      @thumbnail_size   = params[:thumbnail_size]
      @thumbnail_size ||= :thumb
      @decorator        = params[:decorator]
      @decorator ||= Proc.new { |e, element|
        element[0].onclick = link_to(e) 
        element[0].add_css_class(:link)
        Context_Menu_Element.new(e, :show_button => false) { element } 
      }
      params.delete(:decorator)
      params.delete(:thumbnail_size)
      super()
    end

    def element
      HTML.div.media_asset_grid { 
        @entities.map { |e| 
          element = Media_Asset_Thumbnail.new(e, :thumbnail_size => @thumbnail_size)
          @decorator.call(e, element)
        } + HTML.div(:style => 'clear: both;')
      }
    end

  end

end
end
end
end


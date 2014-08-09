
require('aurita')
require('aurita-gui')
Aurita.import_plugin_module :wiki, :gui, :media_asset_thumbnail

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
    # Example: 
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
      @decorator      ||= Proc.new { |e, element|
        element[0].onclick = "#{link_to(e)} return false;"
        element[0].href    = "/aurita/#{resource_url_for(e)}"
        Context_Menu_Element.new(e, :show_button => :prepend) { element } 
      }
      params.delete(:decorator)
      params.delete(:thumbnail_size)
      super()
    end

    def element
      HTML.div.media_asset_grid { 
        @entities.map { |e| 
          thumb_attribs = {}
          thumb_attribs[:thumbnail_size] = @thumbnail_size 
          thumb_attribs[:img_attribs]    = { :rel => "lightbox[set_#{@dom_id}]" }
          element = Media_Asset_Thumbnail.new(e, thumb_attribs)
          @decorator.call(e, element)
        } + HTML.div(:style => 'clear: both;')
      }
    end

  end

end
end
end
end


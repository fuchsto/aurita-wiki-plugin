
require('aurita')
require('aurita-gui')
Aurita.import_plugin_module :wiki, :gui, :media_asset_grid

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_Sortable_Grid < Media_Asset_Grid
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
      @decorator        = params[:decorator]
      @decorator      ||= Proc.new { |e, element|
        element[0].onclick = "#{link_to(e)} return false;"
        element[0].href    = "/aurita/#{resource_url_for(e)}"
        Context_Menu_Element.new(e, :show_button => :prepend) { element } 
      }
      super(entities, params)
    end

    def element
      HTML.div.media_asset_grid(:id => :dom_id) { 
        @entities.map { |e| 
          element = Media_Asset_Thumbnail.new(e, :thumbnail_size => @thumbnail_size)
          @decorator.call(e, element)
        } + HTML.div(:style => 'clear: both;')
      }
    end

    def js_initialize
<<JS
  Sortable.create('#{dom_id}', { 
    tag: 'tr', 
    handle: 'sort_handle', 
    scroll: window, 
    onUpdate: Aurita.Wiki.on_media_assets_reorder
  }); 
JS

  end

end
end
end
end


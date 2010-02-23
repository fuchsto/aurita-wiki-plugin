
require('aurita')
require('aurita-gui')
require('aurita-gui/widget')

Aurita.import_module :gui, :helpers

module Aurita
module Plugins
module Wiki
module GUI
 
  class Media_Asset_Thumbnail < Aurita::GUI::Widget
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers

    def initialize(entity, params={})
      if entity.is_a?(Hash) then
        params  = entity
        @entity = Wiki::Media_Asset.load(:media_asset_id => params[:media_asset_id])
        raise ::Exception.new(params.inspect) unless @entity
      else 
        @entity = entity
      end
      @thumbnail_size   = params[:thumbnail_size]
      @thumbnail_size ||= params[:size]
      @thumbnail_size ||= :thumb
      params.delete(:size)
      params.delete(:thumbnail_size)
      super()
    end

    def element
      HTML.div(:class => [ :media_asset_thumbnail, :bright_bg, @thumbnail_size ]) { 
        HTML.div(:class => [ :image, @thumbnail_size ]) { 
          HTML.img(:src => @entity.icon_path(:size => @thumbnail_size)) 
        } + 
        HTML.div(:class => [:info, :default_bg, @thumbnail_size ]) { 
           HTML.div.title { @entity.title } +
           HTML.div.tags { @entity.tags }
        }
      }
    end

  end

end
end
end
end


require('aurita')
require('aurita-gui')
require('aurita-gui/html')
require('aurita-gui/element')
require('aurita-gui/widget')

Aurita.import_module :gui, :link_helpers
Aurita.import_plugin_module :wiki, 'gui/media_asset_thumbnail'

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Container_Positioning_Button < DelegateClass(Element)
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers

    def initialize(media_container)
      mcid    = media_container.media_container_id
      element = false

      action  = "Wiki::Media_Container/set_position/media_container_id=#{mcid}&vertical"
      icon_v  = '/aurita/images/icons/media_container_v.gif'
      icon_h  = '/aurita/images/icons/media_container_h.gif'
      but_v   = "media_container_pos_button_#{mcid}_v"
      but_h   = "media_container_pos_button_#{mcid}_h"

      style_h = nil
      style_v = nil
      if media_container.vertical then
        style_v = 'display: none;'
      else
        style_h = 'display: none;'
      end

      btn_h = HTML.div.context_menu_button(:id => but_h, :style => style_h, 
          :onclick => "Aurita.load({ element: 'dispatcher', action: '#{action}=f' }); 
                       $('#{but_h}').hide(); $('#{but_v}').show();") { 
        HTML.img(:src => icon_h)
      } 
      btn_v = HTML.div.context_menu_button(:id => but_v, :style => style_v, 
          :onclick => "Aurita.load({ element: 'dispatcher', action: '#{action}=t' }); 
                       $('#{but_v}').hide(); $('#{but_h}').show();") { 
        HTML.img(:src => icon_v)
      } 

      super(HTML.div { btn_v + btn_h })
    end
    
  end

  class Media_Container_Partial < Aurita::GUI::Widget
  include Aurita::GUI
  include Aurita::GUI::Link_Helpers

    def initialize(media_container, params={})
      @media_container = media_container
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
        } + HTML.div(:style => 'clear: both;') + 
        HTML.div.files { 
          @media_container.media_assets(Media_Asset.mime.not_ilike('image/%')).map { |file|
            entry = HTML.div.file_partial { 
              link_to(file) { GUI::Media_Asset_Thumbnail.new(file, :size => :tiny).string }
            }
            link_to(file) { Context_Menu_Element.new(entry, :entity => file).string } 
          }
        } + HTML.div(:style => 'clear: both;') 
      }
    end

    def context_buttons
      Media_Container_Positioning_Button.new(@media_container)
    end

  end

end
end
end
end


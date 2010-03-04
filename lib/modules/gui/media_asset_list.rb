
require('aurita')
require('aurita-gui')
Aurita.import_module :gui, :entity_table
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_module :wiki, 'gui/media_asset_table'
Aurita.import_plugin_module :wiki, 'gui/media_asset_thumbnail'

module Aurita
module Plugins
module Wiki
module GUI

  include Aurita::Plugins::Wiki
  include Aurita::GUI

  # Same as GUI::Media_Asset_Table, but with 
  # column headers disabled by default. 
  #
  class Media_Asset_List < Media_Asset_Table
  include Aurita::GUI

    def initialize(media_assets, params={})
      params[:class] = :media_asset_table unless params[:class]
      super(media_assets, params)
    end
    
  end

  class Media_Asset_Select_List < Media_Asset_List
  include Aurita::GUI

    attr_accessor :row_onclick

    def initialize(media_assets, params={})
      params[:class] = :media_asset_table unless params[:class]
      super(media_assets, params)
      @row_class   = params[:row_class] 
      @row_class ||= Media_Asset_Select_List_Row
      @row_onclick = params[:row_onclick]
    end
    
    def rows
      @rows = @entities.map { |e| 
        onclick = nil
        onclick = @row_onclick.call(e) if @row_onclick
        @row_class.new(e, :parent => self, :onclick => onclick) 
      }
      @rows
    end

  end

  class Media_Asset_Select_List_Row < Entity_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers

    def initialize(media_asset, params={})
      entity = media_asset
      if media_asset.is_a?(Hash) then
        params = media_asset
        entity = Wiki::Media_Asset.load(:media_asset_id => params[:media_asset_id])
      end
      super(entity, params)
      @attrib[:onclick] = "Aurita.Wiki.add_container_attachment(#{media_asset.media_asset_id});" unless @attrib[:onclick]
    end

    def cells
      icon = @entity.icon(:tiny) 
      info = HTML.div { 
        HTML.p.name { @entity.title } +
        HTML.p.tags { @entity.tags  }
      }
      type    = @entity.extension.upcase
      size    = @entity.filesize
      changed = datetime(@entity.changed)
      [ icon, info, type, size, changed ]
    end

  end

  class Media_Asset_Select_Variant_List < Media_Asset_List
  include Aurita::GUI

    attr_accessor :row_onclick, :onselect

    def initialize(media_assets, params={})
      params[:class] = [ :media_asset_table, :media_asset_select_variant_list ] unless params[:class]
      params[:column_css_classes] = [ :icon, :info, :type, :variant ] unless params[:column_css_classes]
      super(media_assets, params)
      @row_class   = params[:row_class] 
      @row_class ||= Media_Asset_Select_Variant_List_Row
      @row_onclick = params[:row_onclick]
      @onselect    = params[:onselect]
    end
    
    def rows
      @rows = @entities.map { |e| 
        onclick = nil
        onclick = @row_onclick.call(e) if @row_onclick
        @row_class.new(e, :parent => self, :onclick => onclick, :onselect => @onselect) 
      }
      @rows
    end

  end

  class Media_Asset_Select_Variant_List_Row < Entity_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers
  include Aurita::GUI::I18N_Helpers

    def initialize(media_asset, params={})
      @onselect = params[:onselect]
      entity    = media_asset
      if media_asset.is_a?(Hash) then
        params = media_asset
        entity = Wiki::Media_Asset.load(:media_asset_id => params[:media_asset_id])
      end
      super(entity, params)
    end

    def cells
      icon = @entity.icon(:tiny) 
      info = HTML.div { 
        HTML.p.name { @entity.title } +
        HTML.p.tags { @entity.tags  }
      }
      type      = @entity.extension.upcase
      select_id = "variant_select_#{@entity.pkey}"
      variant   = Select_Field.new(:name => :variant, 
                                   :id   => select_id)
      variant.options = { :tiny    => tl(:variant_tiny), 
                          :thumb   => tl(:variant_thumb), 
                          :preview => tl(:variant_preview), 
                          :medium  => tl(:variant_medium) }
      onclick = @onselect.call(@entity, "$('#{select_id}').value".to_sym)
#     variant_btn = Text_Button.new(:onclick => Javascript.alert("$('#{select_id}').value".to_sym)) { tl(:ok) }
      variant_btn = Text_Button.new(:onclick => onclick) { tl(:ok) }
      [ icon, info, type, variant + variant_btn ]
    end

  end

  class Media_Asset_Selection_Entry < Media_Asset_Table
    
    def initialize(media_asset, params={})
      entity = media_asset
      if media_asset.is_a?(Hash) then
        params = media_asset
        entity = Wiki::Media_Asset.load(:media_asset_id => params[:media_asset_id])
      end
      params[:class]   = :media_asset_table unless params[:class]
      super([entity], params)
      @row_class   = params[:row_class] 
      @row_class ||= Media_Asset_Selection_Entry_Row
    end

    def rows
      @rows = @entities.map { |e| @row_class.new(e, :parent => self) }
      @rows
    end

  end

  class Media_Asset_Selection_Entry_Row < Entity_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers

    def initialize(media_asset, params={})
      entity = media_asset
      if media_asset.is_a?(Hash) then
        params = media_asset
        entity = Wiki::Media_Asset.load(:media_asset_id => params[:media_asset_id])
      end
      params[:onclick] = "alert('here');"
      super(entity, params)
    end

    def cells
      icon = @entity.icon(:tiny) 
      info = HTML.div { 
        HTML.p.name { @entity.title } +
        HTML.p.tags { @entity.tags  }
      }
      type    = @entity.extension.upcase
      size    = @entity.filesize
      changed = datetime(@entity.changed)
      [ icon, info, type, size, changed ]
    end

  end

  class Media_Asset_Selection_Thumbnail < Media_Asset_Thumbnail
    def element
      entry_id  = "selected_media_asset_#{@entity.pkey()}"
      delete_js = "$('#{entry_id}_field').value = ''; Element.hide('#{entry_id}');" 

      e = HTML.div(:class => [ :media_asset_thumbnail, :bright_bg, @thumbnail_size ]) { 
        HTML.div(:class => [ :image, @thumbnail_size ]) { 
          HTML.img(:src => @entity.icon_path(:size => @thumbnail_size), 
                   :title => @entity.description) 
        } +
        HTML.div(:class => [:info, :default_bg, @thumbnail_size ]) { 
          HTML.div.title { 
              Text_Button.new(:onclick => delete_js, 
                              :style   => 'float: left; margin-right: 4px; margin-top: 4px; padding: 2px; padding-right: 0px; ',
                              :icon    => 'delete_small.png').string +
              @entity.title 
          } + 
          HTML.input(:type  => :hidden, 
                     :id    => "#{entry_id}_field", 
                     :name  => 'selected_media_assets[]', 
                     :value => @entity.media_asset_id)
        }
      }
      e.id = entry_id
      return e
    end
  end

end
end
end
end


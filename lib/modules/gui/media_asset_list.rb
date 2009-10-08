
require('aurita')
require('aurita-gui')
Aurita.import_module :gui, :entity_table
Aurita.import_plugin_model :wiki, :media_asset

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

    def initialize(media_assets, params={})
      params[:class] = :media_asset_table unless params[:class]
      super(media_assets, params)
      @row_class   = params[:row_class] 
      @row_class ||= Media_Asset_Select_List_Row
    end
    
    def rows
      @rows = @entities.map { |e| @row_class.new(e, :parent => self) }
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
      @attrib[:onclick] = "Aurita.Wiki.add_container_attachment(#{media_asset.media_asset_id});"
    end

    def cells
      icon = @entity.icon(:tiny) 
      info = HTML.div { 
        HTML.p.name { @entity.title } +
        HTML.p.tags { @entity.tags  }
      }
      type    = @entity.mime_extension.upcase
      size    = @entity.filesize
      changed = datetime(@entity.changed)
      [ icon, info, type, size, changed ]
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
      type    = @entity.mime_extension.upcase
      size    = @entity.filesize
      changed = datetime(@entity.changed)
      [ icon, info, type, size, changed ]
    end

  end

  class Media_Asset_Selection_Thumbnail < Media_Asset_Thumbnail
    def element
      e = super()
      
      entry_id  = "selected_media_asset_#{@entity.pkey()}"
      delete_js = "$('#{entry_id}_field').value = ''; Element.hide('#{entry_id}');" 

      e.id = entry_id

      e << HTML.div.inline_button(:style => 'bottom: 68px; width: 15px !important;') { 
             HTML.a(:onclick => delete_js) { 'X' } 
           }
      e[0] << HTML.input(:type  => :hidden, 
                         :id    => "#{entry_id}_field", 
                         :name  => 'selected_media_assets[]', 
                         :value => @entity.content_id)
      return e
    end
  end

end
end
end
end


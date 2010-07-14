
require('aurita')
require('aurita-gui')
Aurita.import_module :gui, :entity_table
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_module :wiki, :gui, :media_asset_table

module Aurita
module Plugins
module Wiki
module GUI

  include Aurita::Plugins::Wiki
  include Aurita::GUI

  # Usage: 
  #
  #   as = Media_Asset.find(3).sort_by(:media_asset_id, :desc)
  #   t = Media_Asset_Table.new(as)
  #   t.rows.each { |r|
  #     r.onclick = "foo()"
  #     puts r.entity.mime  # --> 'application/pdf'
  #   }
  #
  class Media_Asset_Sortable_Table < Media_Asset_Table
  include Aurita::GUI

    def initialize(media_assets, params={})
      params[:column_css_classes] = [ :sort, :icon, :info, :type, :size, :date, :date ] unless params[:column_css_classes]
      params[:id]  = :media_asset_sortable_list 

      media_assets = media_assets.sort_by { |m| m.sortpos.to_i }

      @row_class   = params[:row_class] 
      @row_class ||= Media_Asset_Sortable_Table_Row
      @folder_row_class   = params[:folder_row_class]
      @folder_row_class ||= Media_Asset_Folder_Table_Row
      super(media_assets, params)
    end

    def js_initialize
<<JS
  Sortable.create('#{dom_id}_body', { 
    tag: 'tr', 
    handle: 'sort_handle', 
    scroll: window, 
    onUpdate: Aurita.Wiki.on_media_assets_reorder
  }); 
JS
    end
    
  end

  class Media_Asset_Sortable_Table_Row < Media_Asset_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers

    def initialize(media_asset, params={})
      super(media_asset, params)
    end

    def cells
      sort_handle = HTML.div.sort_handle { HTML.img.moveable(:src => '/aurita/images/icons/move.gif') }
      return [ sort_handle ] + super()
    end

  end


end
end
end
end


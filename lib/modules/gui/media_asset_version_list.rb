
require('aurita')
require('aurita-gui')
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_version
Aurita.import_plugin_module :wiki, 'gui/media_asset_list'

module Aurita
module Plugins
module Wiki
module GUI

  include Aurita::Plugins::Wiki
  include Aurita::GUI

  class Media_Asset_Version_List < Media_Asset_List
  include Aurita::GUI

    def initialize(media_assets, params={})
      params[:class]                = :media_asset_table unless params[:class]
      params[:column_css_classes] ||= [ :icon, :info, :version, :user, :date ] 
      params[:headers]            ||= [ '', :description, :version, :user, :date]
      super(media_assets, params)
      @row_class      = params[:row_class] 
      @row_class    ||= Media_Asset_Version_List_Row
    end
    
    def rows()
      @rows  = []
      @rows << Context_Menu_Element.new(@row_class.new(@entities.first, :parent => self), :entity => @entities.first.media_asset) 
      @rows += @entities[1..-1].map { |e| Context_Menu_Element.new(@row_class.new(e, :parent => self), :entity => e) }
      @rows.first.add_css_class(:active_version)
      @rows.first.each { |cell| cell.add_css_class(:darker_bg) }
      @rows
    end

  end

  class Media_Asset_Version_List_Row < Entity_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers
  include Aurita::GUI::I18N_Helpers

    def initialize(media_asset_version, params={})
      super(media_asset_version, params)
    end

    def cells
      icon = @entity.media_asset.icon(:tiny, @entity.version) 
      info = HTML.div { 
        HTML.p.name { @entity.media_asset.title } 
      }
      version = @entity.version
      user    = link_to(@entity.user) { 
        @entity.user.user_group_name 
      } if @entity && @entity.user
      user ||= '-'
      changed = datetime(@entity.timestamp_created)
      [ icon, info, version, user, changed ]
    end

  end

end
end
end
end


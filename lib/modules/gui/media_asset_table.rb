
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

  # Usage: 
  #
  #   as = Media_Asset.find(3).sort_by(:media_asset_id, :desc)
  #   t = Media_Asset_Table.new(as)
  #   t.rows.each { |r|
  #     r.onclick = "foo()"
  #     puts r.entity.mime  # --> 'application/pdf'
  #   }
  #
  class Media_Asset_Table < Entity_Table
  include Aurita::GUI

    def initialize(media_assets, params={})
      params[:column_css_classes] = [ :icon, :info, :type, :size, :date, :date ] unless params[:column_css_classes]
      params[:class] = :media_asset_table unless params[:class]
      super(media_assets, params)
      @row_class   = params[:row_class] 
      @row_class ||= Media_Asset_Table_Row
      @folder_row_class   = params[:folder_row_class]
      @folder_row_class ||= Media_Asset_Folder_Table_Row
    end
    
    def rows()
      if @rows.length == 0 then
        row_vector = []
        @entities.each { |ma|
          case ma
          when Media_Asset
            row_vector << Context_Menu_Element.new(@row_class.new(ma, :parent => self), :entity => ma)
          when Media_Asset_Folder
            row_vector << Context_Menu_Element.new(@folder_row_class.new(ma, :parent => self), :entity => ma)
          end
        }
        @rows = row_vector
      end
      @rows
    end
  end

  class Media_Asset_Table_Row < Entity_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers

    def initialize(media_asset, params={})
      super(media_asset, params)
    end

    def cells
      icon = Context_Menu_Button_Bar.new(@entity.dom_id).to_s + link_to(@entity) { @entity.icon() }
      info = HTML.div { 
        HTML.p.name { link_to(@entity) { @entity.title } } +
        HTML.p.informal { 
           tl(:tags) + ': ' << @entity.tags.split(' ').map { |t| link_to(:controller => 'App_Main', 
                                                                         :action     => :find, 
                                                                         :key        => t) { t } }.join(' ') 
        } +
        HTML.p.informal { 
           tl(:categories) + ': ' << @entity.categories.map { |c| link_to(c) { c.category_name } }.join(', ') 
        }
      }
      type    = @entity.extension.upcase
      size    = @entity.filesize
      created = datetime(@entity.created)
      changed = datetime(@entity.changed)
      [ icon, info, type, size, created, changed ]
    end

  end

  class Media_Asset_Folder_Table_Row < Entity_Table_Row
  include Aurita::GUI
  include Aurita::GUI::Datetime_Helpers
  include Aurita::GUI::Link_Helpers

    def initialize(media_asset, params={})
      super(media_asset, params)
    end

    def cells
      icon = Context_Menu_Button_Bar.new(@entity.dom_id).to_s + link_to(@entity) { @entity.icon() }
      info = HTML.div { 
        HTML.p.name { link_to(@entity) { @entity.physical_path } } +
        HTML.p.tags { @entity.tags }
      }
      type = tl(:folder)
      if @entity.num_files > 0 then
        size = "#{@entity.num_files}&nbsp;#{tl(:files)}<br />#{@entity.total_size.filesize}" 
      else
        size = tl(:folder_is_empty)
      end
      created = datetime(@entity.created)
      changed = datetime(@entity.changed)
      [ icon, info, type, size, created, changed ]
    end

  end

end
end
end
end


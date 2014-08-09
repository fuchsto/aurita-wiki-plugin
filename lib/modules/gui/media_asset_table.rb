
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
      if !params[:column_css_classes] then
        if Aurita.user.may?(:request_files) then
          params[:column_css_classes] = [ :icon, :requested, :info, :type, :size, :date, :date ] 
        else
          params[:column_css_classes] = [ :icon, :info, :type, :size, :date, :date ] 
        end
      end
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
      @requested = media_asset.requested_by?(Aurita.user) 

      super(media_asset, params)
      add_css_class(:requested) if @requested
    end

    def cells
    # requested = @entity.requested_by?(Aurita.user) 
      file_approved = @entity.approved?

      icon = Context_Menu_Button_Bar.new(@entity.dom_id).to_s + link_to(@entity) { @entity.icon() }
      info = HTML.div { 
        HTML.p.name { link_to(@entity) { @entity.title } } +
        HTML.p.informal { 
           tl(:tags) + ': ' << @entity.tags.split(' ').map { |t| link_to(:controller => 'App_Main', 
                                                                         :action     => :find, 
                                                                         :key        => t) { t } }.join(' ') 
        } +
        HTML.p.informal { 
        # Nasty n+1 issue when loading @entity.categories here ...
        #  
        #  tl(:categories) + ': ' << @entity.categories.map { |c| link_to(c) { c.category_name } }.join(', ') 
        }
      }
      request = HTML.div.request_file_button { 
        if file_approved && @requested || !Aurita.user.may?(:request_files) then
          (@requested)? tl(:yes) : tl(:no)
        elsif Aurita.user.may?(:request_files) then 
          HTML.input(:type    => :checkbox, 
                     :checked => ((@requested)? :checked : nil ), 
                     :name    => "request_file_#{@entity.media_asset_id}", 
                     :onclick => "Aurita.Wiki.request_file(this, this.ancestors()[2], #{@entity.media_asset_id});") 
        end
      }
      approve = HTML.div.approve_file_button { 
        if Aurita.user.may?(:approve_requested_files) then
          HTML.input(:type    => :checkbox, 
                     :checked => ((file_approved)? :checked : nil ), 
                     :name    => "request_file_#{@entity.media_asset_id}", 
                     :onclick => "Aurita.Wiki.approve_file(this, this.ancestors()[2], #{@entity.media_asset_id});") 
        else 
          (file_approved)? tl(:yes) : tl(:no)
        end
      }
      type    = @entity.extension.upcase
      size    = @entity.filesize
      created = datetime(@entity.created)
      changed = datetime(@entity.changed)
      
      res  = [ icon ]
      res += [ request ] # if Aurita.user.may?(:request_files)
      res += [ approve ] # if Aurita.user.may?(:approve_requested_files)
      res += [ info, type, size, created, changed ]
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



require('aurita/plugin_controller')

Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :media_asset_folder
Aurita.import_plugin_model :wiki, :media_asset_folder_category
Aurita.import_plugin_module :wiki, 'gui/widgets'
Aurita.import_plugin_module :wiki, 'gui/media_asset_grid'
Aurita.import_plugin_module :wiki, 'gui/media_asset_folder_grid'
Aurita.import_plugin_module :wiki, 'gui/media_asset_list'
Aurita.import_plugin_module :wiki, :custom_form_elements

module Aurita
module Plugins
module Wiki

  class Media_Asset_Folder_Controller < Plugin_Controller
  include Aurita::Plugins::Wiki::GUI
  include Aurita::GUI::Link_Helpers

    guard_interface(:add, :delete, :update, :perform_add, :perform_delete, :perform_update, :delete_recursive, :move_to_folder, :set_picture) { 
      Aurita.user.is_registered? 
    }

    def create_user_folders(params)
      user = params[:user]

      # Create user's own media folder: 
      f = Media_Asset_Folder.create(:physical_path => user.user_group_name, 
                                    :user_group_id => user.user_group_id, 
                                    :access        => 'PRIVATE',
                                    :media_folder_id__parent => 100)
      t = Media_Asset_Folder.create(:physical_path => user.user_group_name+'_trash', 
                                    :user_group_id => user.user_group_id, 
                                    :media_folder_id__parent => 100, 
                                    :access        => 'PRIVATE',
                                    :trashbin => 't')

      Media_Asset_Folder_Category.create(:media_asset_folder_id => f.media_asset_folder_id, 
                                         :category_id => user.category_id)
      Media_Asset_Folder_Category.create(:media_asset_folder_id => t.media_asset_folder_id, 
                                         :category_id => user.category_id)
    end

    def tree_box
      return unless Aurita.user.is_registered? 

      box = Box.new(:type => 'Wiki::Media_Asset_Folder_Box', :class => :topic, :id => :media_folder_box)
      box.header = tl(:media)

      trashbin = Media_Asset_Folder.find(1).with((Media_Asset_Folder.user_group_id == Aurita.user.user_group_id) & 
                                                 (Media_Asset_Folder.trashbin == 't')).entity 

      body = [ ]
      if Aurita.user.may(:create_public_folders) then
        add_folder = HTML.a(:class   => :icon, 
                            :onclick => "Aurita.load({ action: 'Wiki::Media_Asset_Folder/add/'});") { 
          HTML.img(:src => '/aurita/images/icons/add_folder.gif', :class => :icon) + 
          tl(:add_folder) 
        } 
        body << add_folder
      end
      body << tree_box_body 
      box.body = body
      return box
    end
    
    def tree_box_body
      public_folders  = Media_Asset_Folder.hierarchy_level()
      user_folder     = Media_Asset_Folder.hierarchy_level(:filter    => ((Media_Asset_Folder.access == 'PRIVATE') & 
                                                                          (Media_Asset_Folder.user_group_id == Aurita.user.user_group_id)), 
                                                           :parent_id => 100)
      HTML.div.media_asset_folder_tree_box { 
        view_string(:media_asset_folder_box, 
                    :user_folder    => user_folder, 
                    :public_folders => public_folders) 
      }
    end

    def tree_box_level
    # {{{
      parent_id = param(:media_folder_id)
      indent    = param(:indent)
      if !indent then
        indent = 0
        indent_parent_id = parent_id.dup
        while indent_parent_id.to_s != '0' do
          indent_parent_id = Media_Asset_Folder.load(:media_asset_folder_id => indent_parent_id).media_folder_id__parent.to_i
          indent += 1 unless indent_parent_id == 100
        end
      end

      folders   = Media_Asset_Folder.hierarchy_level(:parent_id => parent_id, :indent => indent)
      folders.delete_if { |f| Aurita.user.home_dir == f[:folder] } 
      if folders.length < 1 then 
        puts '<!-- -->'
        return
      end
      render_view(:media_asset_folder_level, 
                  :media_folder_parent_id => parent_id, 
                  :folders => folders, 
                  :indent => indent)
    end # }}}

    def hierarchy_node_select_level
      if param(:media_folder_id__parent).to_s == ''
        puts HTML.div.string 
        return
      end
  
      folders = Media_Asset_Folder.all_with((Media_Asset_Folder.trashbin == 'f') & 
                                            (Media_Asset_Folder.media_folder_id__parent == param(:media_folder_id__parent)))
      folders = folders.sort_by(:physical_path).entities

      puts Hierarchy_Node_Select_Entry.new(:level => param(:level), 
                                           :name => Media_Asset.media_folder_id.to_s, 
                                           :entities => folders).string
    end

    def form_groups
    [
      Media_Asset_Folder.physical_path, 
      Media_Asset_Folder.media_folder_id__parent, 
      Category.category_id
    ]
    end

    def list

      if !(Aurita.user.may_view_folder?(param(:media_folder_id))) then
        puts tl(:no_permission_for_this_folder)
        return
      end
      
      order_params = {
        'desc' => :description, 
        'mime' => :mime, 
        'size' => :filesize, 
        'created' => :created
      }
      
      order_dir   = :asc
      order_dir   = :desc if param(:order_dir) == 'desc'
      order_param = :created
      order_param = order_params[param(:order)] if param(:order)
      
      folder  = Media_Asset_Folder.load(:media_asset_folder_id => param(:media_folder_id))
      assets  = folder.media_assets(:sort => order_param, :sort_dir => order_dir)
      folders = folder.media_asset_folders
      folders.delete_if { |f| !(Aurita.user.may_view_folder?(f)) }
      folder_name = folder.physical_path
      render_view(:media_asset_tab_list, 
                  :media_assets => assets, 
                  :folder_name => folder_name, 
                  :folder_id => folder.media_asset_folder_id, 
                  :media_asset_folders => folders,
                  :user => Aurita.user, 
                  :order => order_param.to_s, 
                  :order_dir => order_dir.to_s, 
                  :trashbin => param(:trashbin), 
                  :media_folder_id => param(:media_folder_id))
    end

    def list_choice

      category_clause = Media_Asset.accessible

      if param(:media_asset_folder_id) then
        if !(Aurita.user.may_view_folder?(param(:media_asset_folder_id))) then
          return HTML.span { tl(:no_permission_for_folder) }
        end
        assets = Media_Asset.all_with((:media_folder_id.is(param(:media_asset_folder_id))) & 
                                      (Content.deleted == 'f') & category_clause).entities
      elsif param(:key) then
        if param(:key).to_s.length < 2 then
          return HTML.span { '&nbsp;' }
        end
        clause = (Media_Asset.deleted == 'f')
        param(:key).to_s.split(' ').each { |key|
          clause = clause & 
                   (Media_Asset.tags.has_element_ilike("#{key}%") | 
                    Media_Asset.title.ilike("#{key}%")) & 
                   category_clause & 
                   (Content.deleted == 'f')
        }
        assets = Media_Asset.find(15).with(clause).entities
      end

      return GUI::Media_Asset_Select_List.new(assets)
    end

    def add
      form = model_form(:model => Media_Asset_Folder, :action => :perform_add)
      form.add(Category_Selection_List_Field.new())
      form[Media_Asset_Folder.media_folder_id__parent].hidden = true
      form[Media_Asset_Folder.media_folder_id__parent].value  = param(:media_folder_id__parent)
      if(['upload_file_section', 'context_menu'].include?(param(:element))) then
        return decorate_form(form)
      else
        return Page.new(:header => tl(:add_folder)) { decorate_form(form) }
      end
    end
    
    def perform_add
    # {{{
      @params[:trashbin] = 'f'
      @params[:user_group_id] = Aurita.user.user_group_id
      @params[:media_folder_id__parent] = '0' unless param(:media_folder_id__parent).to_s != ''
      instance = super() 
      Media_Asset_Folder_Category.create_for(instance, param(:category_ids))
      if param(:media_folder_id__parent) == '0' then
        redirect(:element => 'media_folder_box_body', :to => :tree_box_body)
      else
        parent_id = param(:media_folder_id__parent)
        redirect(:element => "folder_children_#{parent_id}", :to => :tree_box_level, :media_folder_id => parent_id)
      end
      redirect_to(instance)
    end # }}}

    def update
      instance         = Media_Asset_Folder.load(:media_asset_folder_id => param(:media_asset_folder_id))
      form             = update_form()
      category         = Category_Selection_List_Field.new()
      category.value   = instance.category_ids
      form.add(category)
      
      parent_folder_id = instance.media_folder_id__parent
      
      form[Media_Asset_Folder.media_folder_id__parent] = GUI::Hierarchy_Node_Select_Field.new(:name => Media_Asset_Folder.media_folder_id__parent.to_s, 
                                                                                              :label => tl(:parent_folder), 
                                                                                              :model => Media_Asset_Folder, 
                                                                                           #  :exclude_folder_ids => instance.media_asset_folder_id, 
                                                                                              :value => parent_folder_id)
      render_form(form)
    end

    def perform_update
      instance = load_instance()
      # Folder must noy be parent folder of itself
      set_param(:media_folder_id__parent => instance.media_folder_id__parent) if instance.media_folder_id__parent == param(:media_folder_id__parent)

      super()
      
      Media_Asset_Folder_Category.update_for(instance, param(:category_ids))

      if param(:media_folder_id__parent) == '0' then
        redirect(:element => 'media_folder_box_body', :to => :tree_box_body)
      else
        parent_id = param(:media_folder_id__parent)
        redirect(:element => "folder_children_#{parent_id}", :to => :tree_box_level, :media_folder_id => parent_id)
      end
      exec_js(js.Aurita.flash(tl(:changed_have_been_saved)))
    end
    
    def delete
      form = delete_form
      form.add_hidden(Media_Asset_Folder.media_asset_folder_id => param(:media_asset_folder_id))
      form[Media_Asset_Folder.media_folder_id__parent].hidden = true
      render_form(form)
    end
    
    def perform_delete()
      folder_id = param(:media_asset_folder_id)
      super()
      trashbin = Media_Asset_Folder.find(1).with((Media_Asset_Folder.user_group_id == Aurita.user.user_group_id) & 
                                                 (Media_Asset_Folder.trashbin == 't')).entity
      delete_recursive(folder_id, trashbin.media_asset_folder_id) if trashbin
      @params[:media_asset_folder_id] = folder_id
      if param(:media_folder_id__parent) == '0' then
        redirect(:element => 'media_folder_box_body', :to => :tree_box_body)
      else
        parent_id = param(:media_folder_id__parent)
        redirect(:element => "folder_children_#{parent_id}", :to => :tree_box_level, :media_folder_id => parent_id)
      end

      exec_js("Aurita.Wiki.after_media_asset_folder_delete(#{folder_id}); ")
    end
    
    def delete_recursive(media_asset_folder_id, trashbin_folder_id)
      Media_Asset_Folder.all_with(Media_Asset_Folder.media_folder_id__parent == media_asset_folder_id).each { |f|
        @params[:media_asset_folder_id] = f.media_asset_folder_id
        perform_delete
      }

      Media_Asset.all_with(Media_Asset.media_folder_id == media_asset_folder_id).each { |a|
        asset = Media_Asset.load(:media_asset_id => a.media_asset_id)
        asset[:media_folder_id] = trashbin_folder_id
        asset.commit
      }
    end

    def show
      folder = load_instance()
      table  = table_widget
      render_view(:media_asset_folder, 
                  :table  => table, 
                  :view   => :table, 
                  :folder => folder)
    end

    def table_widget
      folder        = load_instance
      sort          = param(:sort, :created)
      sort_dir      = param(:sort_dir, :asc)
      assets  = []
      folders = []
      folder_sort_params = {}
      if sort == :title then
        folder_sort_params[:sort]     = :physical_path  
        folder_sort_params[:sort_dir] = sort_dir
      end
      folders = folder.media_asset_folders(folder_sort_params)
      assets  = folder.media_assets(:sort => sort, :sort_dir => sort_dir)

      table         = GUI::Media_Asset_Table.new(folders + assets)
      headers       = [ '&nbsp;' ] 
      headers      += [ HTML.th { tl(:description) }, HTML.th { tl(:filetype) }, HTML.th { tl(:filesize) }, HTML.th { tl(:created) }, HTML.th { tl(:changed) } ]
      header_idx = 1
      [ 'title', 'mime', 'filesize', 'created', 'changed' ].each { |s|
        if sort.to_s == s && sort_dir.to_s == 'asc' then dir = 'desc' 
        else dir = 'asc' 
        end
        headers[header_idx].onclick = link_to(folder, :action   => :show_table, 
                                              :element => "media_asset_folder_table_#{folder.media_asset_folder_id}", 
                                              :sort    => s, :sort_dir => dir)
        headers[header_idx].add_css_class(:active) if s == sort.to_s
        header_idx += 1
      }
      table.headers = headers
      even = true
      table.rows.each { |r|
        r.add_css_class :even if even
        r.add_css_class :odd  if !even
        even = !even
      }
      table
    end

    def show_table
      table_widget()
    end

    def show_grid
      folder = load_instance()
      media_folder_id = param(:media_asset_folder_id, 0)
      per_page        = param(:per_page, 30)
      page            = param(:page, 0)
      sort            = param(:sort, :created)
      sort_dir        = param(:sort_dir, :asc)
      folders = []
      assets  = []

      folder_sort_params = {}
      if sort == :title then
        folder_sort_params[:sort]     = :physical_path  
        folder_sort_params[:sort_dir] = sort_dir
      end
      folders = folder.media_asset_folders(folder_sort_params)
      assets  = folder.media_assets(:sort => sort, :sort_dir => sort_dir)
    
      folder_grid = Media_Asset_Folder_Grid.new(folders)
      asset_grid  = Media_Asset_Grid.new(assets)
      
      content = HTML.div.topic_inline { folder_grid.to_s + asset_grid.to_s }
      render_view(:media_asset_folder, 
                  :table  => content, 
                  :view   => :grid, 
                  :folder => folder)
    end
    alias grid show_grid

    def show_top_public_folders
      render_view(:media_asset_folder, 
                  :view_content => folder_content_string(:media_folder_id => 306, # Events folder
                                                         :page => 1)) 
    end

    def move_to_folder()
      folder = Media_Asset_Folder.load(:media_asset_folder_id => param(:media_folder_asset_id).gsub('folder_drag__',''))
      folder[:media_folder_id__parent] = param(:media_folder_id).gsub('folder_','')
      folder.commit
    end

  end

end
end
end




require('aurita/plugin')

module Aurita
module Plugins
module Wiki


  # Usage: 
  #
  #  plugin_get(Hook.right_column)
  #
  class Plugin < Aurita::Plugin::Manifest

    register_hook(:controller => Media_Asset_Folder_Controller, 
                  :method     => :create_user_folders, 
                  :hook       => Hook.main.after_register_user)
    register_hook(:controller => Article_Controller, 
                  :method     => :recent_changes_in_category, 
                  :hook       => Hook.main.workspace.recent_changes_in_category)
    register_hook(:controller => Media_Asset_Controller, 
                  :method     => :recent_changes_in_category, 
                  :hook       => Hook.main.workspace.recent_changes_in_category)
    register_hook(:controller => Article_Controller, 
                  :method     => :toolbar_buttons, 
                  :hook       => Hook.main.toolbar)
    register_hook(:controller => Media_Asset_Controller, 
                  :method     => :toolbar_buttons, 
                  :hook       => Hook.main.toolbar)
    register_hook(:controller => Article_Controller, 
                  :method     => :viewed_articles_box, 
                  :hook       => Hook.main.right_column)
    register_hook(:controller => Article_Controller, 
                  :method     => :changed_articles_box, 
                  :hook       => Hook.main.right_column)
    register_hook(:controller => Media_Asset_Folder_Controller, 
                  :method     => :tree_box, 
                  :hook       => Hook.main.left_column.top)
    register_hook(:controller => Article_Controller, 
                  :method     => :find, 
                  :hook       => Hook.main.find)
    register_hook(:controller => Article_Controller, 
                  :method     => :find_full, 
                  :hook       => Hook.main.find_full)
    register_hook(:controller => Media_Asset_Controller, 
                  :method     => :find, 
                  :hook       => Hook.main.find)
    register_hook(:controller => Article_Controller, 
                  :method     => :own_articles_box, 
                  :hook       => Hook.main.my_place.left)
    register_hook(:controller => Article_Controller, 
                  :method     => :decorate_hierarchy_entry, 
                  :hook       => Hook.main.hierarchy.entry_decorator)
    register_hook(:controller => Article_Controller, 
                  :method     => :list_category, 
                  :hook       => Hook.main.category.list)
                  
  end

end
end
end



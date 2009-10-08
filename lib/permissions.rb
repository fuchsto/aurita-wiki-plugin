
require('aurita/plugin')

module Aurita
module Plugins
module Wiki


  # Usage: 
  #
  #  plugin_get(Hook.right_column)
  #
  class Permissions < Aurita::Plugin::Manifest

    register_permission(:create_articles, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:edit_foreign_articles, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:create_public_folders, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:reactivate_foreign_article_versions, 
                        :type    => :bool, 
                        :default => true)
  end

end
end
end


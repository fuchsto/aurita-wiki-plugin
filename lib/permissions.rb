
require('aurita/plugin')

module Aurita
module Plugins
module Wiki


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
    register_permission(:view_foreign_article_versions, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:view_foreign_media_versions, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:reactivate_foreign_article_versions, 
                        :type    => :bool, 
                        :default => true)

    register_permission(:delete_foreign_articles, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:change_meta_data_of_foreign_articles, 
                        :type    => :bool, 
                        :default => true)

    register_permission(:delete_foreign_files, 
                        :type    => :bool, 
                        :default => true)
    register_permission(:change_meta_data_of_foreign_files, 
                        :type    => :bool, 
                        :default => true)

    register_permission(:edit_extended_article_options, 
                        :type    => :bool, 
                        :default => true)
  end

end
end
end


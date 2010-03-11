
require('aurita')
Aurita.import_plugin_model :wiki, :strategies, :abstract_folder_access

module Aurita
module Plugins
module Wiki

  class Category_Based_Folder_Access < Abstract_Folder_Access

    def permits_read_access_for(user)
      return true if user.is_admin? 
      return true if user.user_group_id == @instance.user_group_id
  
      return false unless user.readable_category_ids.first
      return false unless @instance.category_ids.first

      common_cats = (user.readable_category_ids) & (@instance.category_ids)
      return (common_cats && common_cats.first) 
    end

    def permits_edit_for(user)
      return true if user.is_admin? 
      return true if user.user_group_id == @instance.user_group_id
      common_cats = (user.writeable_category_ids) & (@instance.category_ids)
      return (common_cats && common_cats.first) 
    end

    def permits_write_access_for(user)
      return true if user.is_admin? 
      return true if user.user_group_id == @instance.user_group_id

      common_cats = (user.writeable_category_ids) & (@instance.category_ids)
      return (common_cats && common_cats.first) 
    end

    def permits_subfolders_for(user)
      return true if @instance.user_group_id == user.user_group_id
      return false unless permits_write_access_for(@instance)
      return true if @instance.is_child_of?(user.home_dir)
      return true if (!@instance.is_user_folder?) && user.may(:create_public_folders)
    end

    def self.on_use(klass, params=false)
      klass.extend(Categorized_Access_Class_Behaviour)
      if params then
        klass.use_category_map(params[:managed_by], params[:mapping])
      end
    end

  end

end
end
end


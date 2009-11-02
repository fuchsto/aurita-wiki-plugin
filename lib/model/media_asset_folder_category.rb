
require('aurita/model')
Aurita::Main.import_model :category
Aurita::Main.import_model :user_category
Aurita.import_plugin_model :wiki, :media_asset_folder

module Aurita
module Plugins
module Wiki

  class Media_Asset_Folder_Category < Aurita::Model
      
    table :media_asset_folder_category, :public
    primary_key :folder_category_id, :media_asset_folder_category_id_seq

    def self.create_for(folder, category_ids)
      category_ids.each { |cid| 
        create(:media_asset_folder_id => folder.media_asset_folder_id, 
               :category_id => cid)
      }
    end

    def self.update_for(folder, category_ids)
      delete { |cc|
        cc.where(Media_Asset_Folder_Category.media_asset_folder_id == folder.media_asset_folder_id)
      }
      create_for(folder, category_ids)
    end
  end

  class Media_Asset_Folder < Aurita::Model
    def category_ids
      if !@category_ids then
        @category_ids = Media_Asset_Folder_Category.select_values(:category_id) { |cid|
          cid.where(:media_asset_folder_id.eq(media_asset_folder_id))
        }
      end
      return @category_ids
    end

  end 

end
end

module Main

  class User_Group < Aurita::Model

    def may_view_folder?(media_asset_folder)
      return true if Aurita.user.is_admin? 

      if !(media_asset_folder.kind_of?(Aurita::Model)) then
        media_asset_folder = Aurita::Plugins::Wiki::Media_Asset_Folder.load(:media_asset_folder_id => media_asset_folder)
      end
      raise ::Exception.new('Folder does not exist') unless media_asset_folder
  
      return false unless Aurita.user.readable_category_ids.first
      return false unless media_asset_folder.category_ids.first

      common_cats = (Aurita.user.readable_category_ids) & (media_asset_folder.category_ids)
      return common_cats && common_cats.first
    end
    alias may_view_folder may_view_folder? 

    # Folder may be edited if user is admin or folder has 
    # been created by user himself. 
    def may_edit_folder?(media_asset_folder)
      return true if Aurita.user.is_admin? 

      if !(media_asset_folder.kind_of?(Aurita::Model)) then
        media_asset_folder = Aurita::Plugins::Wiki::Media_Asset_Folder.load(:media_asset_folder_id => media_asset_folder)
      end
      raise ::Exception.new('Folder does not exist') unless media_asset_folder
      return Aurita.user.user_group_id == media_asset_folder.user_group_id
    end

    # User may write (upload files or create subfolders) to 
    # a folder if read/write permissions are granted to one 
    # of the folders categories. 
    # User also needs permission create_public_folders in 
    # case folder has not been created by user himself. 
    def may_write_to_folder?(media_asset_folder)
      return true if Aurita.user.is_admin? 

      if !(media_asset_folder.kind_of?(Aurita::Model)) then
        media_asset_folder = Aurita::Plugins::Wiki::Media_Asset_Folder.load(:media_asset_folder_id => media_asset_folder)
      end
      return true if media_asset_folder.user_group_id == Aurita.user.user_group_id
      raise ::Exception.new('Folder does not exist') unless media_asset_folder
      return ((media_asset_folder.category_ids - Aurita.user.writeable_category_ids).length < media_asset_folder.category_ids.length)
    end

    
    def may_create_subfolder_in_folder?(media_asset_folder)
      return false unless may_write_to_folder?(media_asset_folder)
      return true if media_asset_folder.user_group_id == Aurita.user.user_group_id
      return true if media_asset_folder.is_child_of?(Aurita.user.home_dir)
      return true if (!media_asset_folder.is_user_folder?) && Aurita.user.may(:create_public_folders)
    end

  end

end
end


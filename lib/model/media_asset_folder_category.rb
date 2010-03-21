
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
        }.flatten.map { |cid| cid.to_i }
      end
      return @category_ids
    end

  end 

end
end
end



require('aurita/model')
Aurita::Main.import_model :content
Aurita.import_module :access_strategy
Aurita.import_plugin_model :wiki, :asset
Aurita.import_plugin_model :wiki, :strategies, :category_based_folder_access
Aurita.import_plugin_model :wiki, :media_asset_folder_category

module Aurita
module Plugins
module Wiki

  class Media_Asset_Folder < Aurita::Model

    table :media_asset_folder_meta, :public
    primary_key :media_asset_folder_meta_id, :media_asset_folder_category_id_seq
    
    expects :media_asset_folder_id
    
  end

end
end
end



require('aurita/model')

module Aurita
module Plugins
module Wiki

  class Media_Asset_Version < Aurita::Model

    table :media_asset_version, :public
    primary_key :media_asset_version_id, :media_asset_version_id_seq

    has_a User_Group, :user_group_id

    def user
      @user = User_Group.load(:user_group_id => user_group_id) unless @user
      @user
    end

    def media_asset
      @media_asset ||= Wiki::Media_Asset.load(:media_asset_id => media_asset_id)
      @media_asset
    end

  end 

end # module
end # module
end # module


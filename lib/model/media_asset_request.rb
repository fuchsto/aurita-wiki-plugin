
require('aurita/model')
Aurita.import_plugin_model :wiki, :media_asset
Aurita::Main.import_model :user_group


module Aurita
module Plugins
module Wiki

  class Media_Asset_Request < Aurita::Model

    table :media_asset_request, :public
    primary_key :media_asset_request_id, :media_asset_request_id_seq

    has_a User_Group, :user_group_id
    has_a Media_Asset, :media_asset_id
    
    def user
      @user = User_Group.load(:user_group_id => user_group_id) unless @user
      @user
    end

    def media_asset
      @media_asset ||= Wiki::Media_Asset.load(:media_asset_id => media_asset_id)
      @media_asset
    end

  end 

  class Media_Asset < Asset

    def request_by(user)
      if user.may?(:request_files) then
        req = Media_Asset_Request.find(1).with(:media_asset_id => media_asset_id, 
                                               :user_group_id  => user.user_group_id).entity
        return req
      else
        return nil
      end
    end

    def requested_by?(user)
      !request_by(user).nil?
    end

    def requested?
      !Media_Asset_Request.find(1).with(:media_asset_id => media_asset_id).entity.nil?
    end

  end

end # module Wiki
end # module Plugins

module Main

  class User_Group < Aurita::Model

    def may_download_file?(media_asset)
      (Aurita.user.may_view_content?(media_asset)) && 
      (Aurita.user.may?(:download_files) ||
       Aurita.user.may?(:download_approved_files) && media_asset.approved?)
    end

  end

end # module Main
end # module Aurita


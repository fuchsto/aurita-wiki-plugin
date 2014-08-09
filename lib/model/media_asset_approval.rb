
require('aurita/model')
Aurita.import_plugin_model :wiki, :media_asset
Aurita::Main.import_model :user_group


module Aurita
module Plugins
module Wiki

  class Media_Asset_Approval < Aurita::Model

    table :media_asset_approval, :public
    primary_key :media_asset_approval_id, :media_asset_approval_id_seq

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

    def approval_by(user)
      if user.may?(:approve_requested_files) then
        req = Media_Asset_Approval.find(1).with(:media_asset_id => media_asset_id, 
                                                :user_group_id  => user.user_group_id).entity
        return req
      else
        return nil
      end
    end

    def approved_by?(user)
      !approval_by(user).nil?
    end

    def approved?
      approved     = true
      has_approver = false
      categories.each { |c|
        approver       = c.approver
        has_approver ||= !approver.nil?
        approved       = false if approver && !approved_by?(approver) 
      }
      approved && has_approver
    end

  end

end # module Wiki
end # module Plugins

module Main

  class User_Group < Aurita::Model

    def may_approve_file?(media_asset)
      Aurita.user.may_view_content?(media_asset) && 
      Aurita.user.may?(:approve_requested_files) 
    end

  end

end # module Main
end # module Aurita


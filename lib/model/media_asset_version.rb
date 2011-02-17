
require('aurita/model')

module Aurita
module Plugins
module Wiki

  # A Media_Asset_Version instance stores attribute values 
  # of a Media_Asset instance that are overwritten when committing 
  # a new version. 
  # If there has not been committed a new version, the Media_Asset
  # instance's version number is 0. 
  # Thus, when requesting version 0 of a file, this corresponds to 
  # the *most recent* version of the media asset, and requesting 
  # version 1 of a media asset corresponds to the original media asset 
  # before the first new version has been committed. 
  #
  # When committing a new version, the old attribute values are 
  # stored in a Media_Asset_Version instance with version number 1, 
  # and the file associated to the old version is moved from 
  # asset_<media_asset_id>.<ext> to asset_<media_asset_id>.1.ext. 
  # 
  # An example: 
  #
  # table media_asset: 
  # 
  #   media_asset_id | version | extension | ...
  #               23 |       3 | png     <-- the current version
  #               42 |       0 | png     <-- no other versions exist
  #
  # table media_asset_version: 
  # 
  #   media_asset_id | version | extension | ...
  #               23 |       1 | jpg     <-- the original file
  #               23 |       2 | pdf     <-- the first change (one before current version)
  #
  # When committing a new version for media_asset with id 42, the 
  # records could look like this: 
  #
  # table media_asset: 
  # 
  #   media_asset_id | version | extension | ...
  #               23 |       3 | png
  #               42 |       2 | jpg     <-- Note that version went from 0 to 2 (not 1!)
  #
  # table media_asset_version: 
  # 
  #   media_asset_id | version | extension | ...
  #               23 |       1 | jpg 
  #               23 |       2 | pdf
  #               42 |       1 | png     <-- the old version 0 became version 1
  #
  # In this case, the original file for media_asset 42 was a PNG, 
  # and the next version is a JPG. The extension of version 1 (the 
  # stored original file) is saved in media_asset_version. 
  #
  class Media_Asset_Version < Aurita::Model

    table :media_asset_version, :public
    primary_key :media_asset_version_id, :media_asset_version_id_seq

    has_a User_Group, :user_group_id
    
    def self.before_create(args)
      args[:mime]           ||= '?'
      args[:version]        ||= -1
      args[:media_asset_id] ||= 0
      args
    end

    def self.create_from_media_asset(media_asset)
      create(
        :media_asset_id    => media_asset.media_asset_id, 
        :version           => media_asset.version, 
        :mime              => media_asset.mime, 
        :user_group_id     => media_asset.user_group_id, 
        :timestamp_created => media_asset.created
      )
    end

    def extension
      e = mime.split('/')[-1].downcase
      e = 'jpg' if e == 'jpeg'
      e
    end

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


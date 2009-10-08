

require('aurita/model')
Aurita.import_plugin_model :wiki, :media_asset

module Aurita
module Plugins
module Wiki


  class Media_Asset_Download < Aurita::Model

    table :media_asset_download, :public
    primary_key :media_asset_download_id, :media_asset_download_id_seq

    has_a Media_Asset, :media_asset_id

    aggregates Aurita::Main::User_Group, :user_group_id

    def self.for(asset)
      if asset.is_a? Media_Asset then
        media_asset_id = asset.media_asset_id
      else
        media_asset_id = asset
      end

      select { |d|
          d.where(d.media_asset_id == media_asset_id)
          d.order_by(:time, :desc)
      }
    end

    def user_group
      User_Group.load(:user_group_id => user_group_id)
    end

    def self.num_downloads(params={})
      time_from = params[:from].strftime("%Y-%m-%d %H%M%S")
      time_to   = params[:to].strftime("%Y-%m-%d %H%M%S")
      downloads = select_value('count(*)') { |ua|
        ua.where((ua.time >= time_from) & (ua.time <= time_to))
      }.to_i 
      downloads
    end

  end

end
end
end


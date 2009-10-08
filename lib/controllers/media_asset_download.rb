

require('aurita/plugin_controller')
Aurita.import_plugin_model :wiki, :media_asset_download

module Aurita
module Plugins
module Wiki

  class Media_Asset_Download_Controller < Plugin_Controller

    def box
      stats = Media_Asset_Download.for(param(:media_asset_id))
      return unless stats && stats.length > 0

      box = Box.new(:class => :topic_inline, :id => :media_asset_downloads_box)
      box.header = tl(:media_asset_download_stats)
      
      list = HTML.ul
      stats.each { |e|
        list << HTML.li { datetime(e.time.to_s) + ' - ' << link_to(e.user_group) }
      }
      box.body = list

      return box
    end

  end

end
end
end


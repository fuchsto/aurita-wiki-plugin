
require('aurita/plugin_controller')

module Aurita
module Plugins
module Wiki

  class Media_Asset_Statistics_Controller < Plugin_Controller

    def box
    end

    def box_body
      [
        HTML.button.icon { tl(:show_user_statistics) }, 
        HTML.button.icon { tl(:show_media_statistics) }
      ]
    end

    def show_user_stats
    end

    def show_media_stats
    end

  end

end
end
end


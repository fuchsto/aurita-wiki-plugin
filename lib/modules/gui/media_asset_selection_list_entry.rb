
require('aurita-gui/widget')

module Aurita
module Plugins
module Wiki

  class Media_Asset_Selection_List_Entry < Aurita::GUI::Widget

    def initialize(params={})
      @params         = params
      @media_asset_id = params[:media_asset_id]
      super()
      add_css_class(:media_asset_selection_list_entry)
    end

    def element
      random_id = "media_asset_selection_list_entry_#{@media_asset_id}_#{rand(1000)}"
      HTML.li(:id => random_id) { 
        HTML.div { 
          HTML.img.icon(:src     => '/aurita/images/icons/delete_small.png', 
                        :onclick => "$('#{random_id}').remove();" ) + 
          HTML.div.thumb { HTML.img(:src => "/aurita/assets/tiny/asset_#{@media_asset_id}.jpg") } +
          HTML.div.label { @params[:label] }
        } + 
        HTML.input(:type => :hidden, :name => "#{@params[:name]}", :value => @media_asset_id) 
      }
    end

  end

end
end
end


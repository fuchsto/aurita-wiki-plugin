
require('aurita-gui/widget')
Aurita.import_module :gui, :link_helpers
Aurita.import_module :gui, :datetime_helpers


module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_List_Entry < Aurita::GUI::Widget
    include Aurita::GUI::Link_Helpers
    include Aurita::GUI::Datetime_Helpers

    def initialize(media_asset, params={})
      @params = params
      @entity = media_asset
      super()
    end

    def element
      user = @entity.user_profile
      cats = @entity.categories
      if cats.length == 1 then
        cat = cats[0]
        in_cats = "#{tl(:in_category)} #{link_to(cat) { cat.category_name } }"
      elsif cats.length > 1 then
        in_cats = "#{tl(:in_categories)} "
        in_cats << cats.map { |cat|
          "#{link_to(cat) { cat.category_name } }"
        }.join(', ')
      end
      HTML.div(:class => [ :media_asset, :index_entry, :listing ]) { 
        HTML.div.image { link_to(@entity) { @entity.icon(:thumb) } } + 
        HTML.div { link_to(@entity) { HTML.b { @entity.title } } } + 
        HTML.div { datetime(@entity.changed) } +
        HTML.div { "#{link_to(user) { user.label }} #{in_cats}" } 
      }
    end

  end

end
end
end
end

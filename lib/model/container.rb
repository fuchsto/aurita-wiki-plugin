
require('aurita/model')
begin
  require('lore/model/behaviours/movable')
rescue ::Exception => ignore
  require('lore/behaviours/movable')
end

Aurita.import_plugin_model :wiki, :article
Aurita::Main.import_model :content

module Aurita
module Plugins
module Wiki

  class Container < Aurita::Model
  extend Lore::Behaviours::Movable

    table :container, :public

    primary_key :content_id_parent
    primary_key :asset_id_child
    
    has_a Content, :content_id_parent
    has_a Asset, :asset_id_child

    ordered_by :sortpos

    def asset
      Asset.load(:asset_id => asset_id_child)
    end

    def article
      Article.load(:content_id => content_id_parent)
    end

    # Automatically re-sorts containers in a new 
    # instances article. 
    #
    def self.before_create(params)
      # Shift all containers after newly created instance 
      # by 1 position: 
      update { |c|
        c.where((content_id_parent == params[:content_id_parent]) & 
                (sortpos >= params[:sortpos]))
        c.set(:sortpos => sortpos + 1)
      }
    end

  end 

  class Article < Aurita::Main::Content
    def parts
      Asset.polymorphic_select { |a|
        a.join(Container).on(Container.asset_id_child == Asset.asset_id) { |c|
          c.where(Container.content_id_parent == content_id)
          c.order_by(Container.sortpos, :asc)
        }
      }.to_a
    end
  end

end # module
end # module
end # module

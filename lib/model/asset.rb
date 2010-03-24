
require('aurita/model')
Aurita::Main.import_model :content

module Aurita
module Plugins
module Wiki

  class Asset < Content

    table :asset, :public
    primary_key :asset_id, :asset_id_seq
    
    is_a Content, :content_id

    is_polymorphic :concrete_model

    def article
      @parent_article ||= Article.select { |a|
        a.where(Article.content_id == (Container.select(:content_id_parent) { |pcid|
          pcid.where(Container.asset_id_child == asset_id)
        }))
        a.limit(1)
      }.first
      return @parent_article 
    end
    alias parent_article article

    def accept_visitor(v)
      v.visit(self)
    end

    def version_dump
      text
    end

  end 

end # module
end # module
end # module


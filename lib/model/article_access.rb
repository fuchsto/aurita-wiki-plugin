
require('aurita/model')
Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_model :wiki, :asset

module Aurita
module Plugins
module Wiki
    
  class Article_Access < Aurita::Model

    table :article_access, :public
    primary_key :article_id
    
    has_a Article, :article_id
    has_a User_Group, :user_group_id

    def self.before_create(args)
      Article_Access.delete { |aa|
        aa.where((aa.article_id == args[:article_id]) & 
                 (aa.user_group_id == args[:user_group_id]))
      }
    end

    def self.of_user(user_id, amount=5) 
      Article.access_of_user(user_id, amount)
    end
    
  end 

  Article.prepare(:access_of_user, Lore::Type.integer, Lore::Type.integer) { |a| 
        a.join(Article_Access).using(:article_id) { |aa|
          aa.where(Article_Access.user_group_id == Lore::Clause.new('$1'))
          aa.order_by(Article_Access.changed, :desc)
          aa.limit(Lore::Clause.new('$2'))
        }
  }

end # module
end # module
end # module


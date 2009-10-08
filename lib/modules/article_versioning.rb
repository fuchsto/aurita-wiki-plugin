
module Aurita
module Plugins
module Wiki

  class Article_Versioning
    
    # Convert article dump to full hierarchy, e.g. for 
    # Article_Full_Hierarchy_Decorator. 
    def self.dump_to_full_hierarchy(dump)
      hierarchy = dump
      article_content_id = hierarchy.keys.first
      article_set = hierarchy[content_id]
      article_set[:instance] = Article.find(1).with(:article_id.is(article_id)).entity

      # TODO: Use plugin hook for different container types here. 
      article_set[:text_assets].map { |ta|
        ta[:text_asset] = Text_Asset.new(:text => ta[:text_asset], 
                                         :display_text => ta[:text_asset], 
                                         :tags => 'text', 
                                         :content_id => 0, 
                                         :text_asset_id => 0)
        ta[:media_assets].map { |ma| 
          ma = Media_Asset.load(:media_asset_id => ma)
        }
        ta[:todo_assets].map { |todo|
          todo = Todo_Asset.load(:todo_asset_id => todo)
        }
        ta[:form_assets].map { |form|
          todo = Form_Asset.load(:form_asset_id => form)
        }
      }
      hierarchy
    end

    # TODO: To be implemented
    def self.rollback
    end

    # TODO: To be implemented
    def self.diff
    end

  end

end
end
end


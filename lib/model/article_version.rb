
require('aurita/model')

module Aurita
module Plugins
module Wiki

  class Article_Version < Aurita::Model

    table :article_version, :public
    primary_key :article_version_id, :article_version_id_seq
    
    has_a User_Group, :user_group_id

    def user
      @user = User_Group.load(:user_group_id => user_group_id) unless @user
      @user
    end
    
    def categories
      Category.select { |c|
        c.join(Content_Category).on(Category.category_id == Content_Category.category_id) { |cc|
          cc.join(Article).on(Article.content_id == Content.content_id) { |a|
            a.where(Article.article_id == article_id)
          }
        }
      }
    end
    
  end

  class Article < Content

    def commit_version(action_type='CHANGED')
      last_version = latest_version
      dump = accept_visitor(Aurita::Plugins::Wiki::Article_Hierarchy_Visitor.new).inspect
      version = 0
      version = (last_version.version.to_i + 1) if last_version
      if !last_version || dump != last_version.dump then
        Article_Version.create(:article_id => article_id, 
                               :version => version, 
                               :user_group_id => Aurita.user.user_group_id, 
                               :action_type => action_type, 
                               :dump => dump)
      end
    end

    def latest_version_number
      Article_Version.value_of.max(:version).with(Article_Version.article_id == article_id).to_i
    end
    def latest_version
      Article_Version.find(1).with((Article_Version.article_id == article_id) & (Article_Version.version == latest_version_number)).entity
    end

    def load_version_dump(version)
      dump = eval(Article_Version.find(1).with((Article_Version.article_id == article_id) & 
                                               (Article_Version.version == version)).entity.dump)
    end
    def diff_versions(version_a, version_b)
      Article_Version.find(2).with((Article_Version.article_id == article_id) & 
                                   (Article_Version.version == version_a) | 
                                   (Article_Version.article_id == article_id) & 
                                   (Article_Version.version == version_b)).sort_by(:version, :asc).entities
      
    end
    
  end
  
end
end
end


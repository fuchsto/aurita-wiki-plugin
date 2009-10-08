
require('aurita/model')
Aurita::Main.import_model :content
Aurita::Main.import_model :content_category
Aurita.import_plugin_model :wiki, :asset
Aurita.import_plugin_model :wiki, :text_asset
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_model :wiki, :article_version

module Aurita
module Plugins
module Wiki
  
  class Article < Content

    table :article, :public
    primary_key :article_id, :article_id_seq
    
    is_a Content, :content_id

    has_n Asset, :content_id
    
    use_label :title
    def label_string
      title
    end

    expects :title
    expects :tags, Content

    validates :title, :maxlength => 100, :mandatory => true

    html_escape_values_of :title

    def readable_id
      title.downcase.gsub(' ','_')
    end

    # Extends Content.touch by also commiting a new Article_Version entity. 
    def self.touch(content_id, action='CHANGED')
      super(content_id)
      Article.find(1).with(Article.content_id == content_id).entity.commit_version(action)
    end
    # Same as Article.touch(article.content_id
    def touch
      Article.touch(content_id)
    end

    # Return highest version number of this 
    # article. 
    def max_version
      Article_Version.value_of.max(:version).with(Article_Version.article_id == article_id).to_i
    end

    # Returns part of an article hierarchy. 
    # Immediate subs of an article are its Text_Asset 
    # instances. 
    # Article#subs returns a hash like: 
    #
    #  { :text_assets => [ text_asset, ... ]
    #
    # Text_Asset instances are ordered by their position 
    # in the article
    #
    def subs
      text_assets = Text_Asset.select { |c|
        c.join(Container).on(Container.content_id_child == Text_Asset.content_id) { |ta|
          ta.where(Container.content_id_parent == content_id) 
          ta.order_by(Container.sortpos, :asc)
        }
      } 
      { :text_assets => text_assets }
    end

    def accept_visitor(v)
      v.visit_article(self)
    end

    # Returns Text_Asset instances (paragraphs) of 
    # this article, as array, ordered by their positions. 
    def text_assets
      text_assets = []
      Container.all_with(Container.content_id_parent == content_id).sort_by(:sortpos, :asc).entities.each { |c|
        text_assets += Text_Asset.all_with(Asset.content_id == c.content_id_child).entities
      }
      text_assets
    end

    # Returns Text_Asset instances (paragraphs) of 
    # this article, as array, ordered by their appearance 
    # in the article. 
    # Note that Media_Asset instances can only be part 
    # of an article as file attachment of its Text_Asset 
    # instances. 
    #
    def media_assets(params={})
      amount   = params[:max]
      amount ||= params[:amount]
      amoutn ||= :all
      Media_Asset.find(amount).with(Media_Asset.content_id.in(Container.select(:content_id_child) { |mcid|
          mcid.where(Container.content_id_parent.in(Container.select(:content_id_child) { |tcid|
                        tcid.where(Container.content_id_parent == content_id)
            })
          )
        })
      ).entities
    end
    
  end 

  Article.prepare(:recently_changed, Lore::Type.integer) { |a|
    a.where(true)
    a.order_by(:changed, :desc)
    a.limit(Lore::Clause.new('$1'))
  }

end # module
end # module

module Main

  class Content_Access < Aurita::Model
    include Aurita::Plugins::Wiki

    has_a Article, :content_id

    def self._of_user(user_id, amount=10, res_type=:any)
      result = Array.new
      if [:any, :article].include? res_type then
        result += Article.select { |a|
          a.join(Content_Access).on(Article.content_id == Content_Access.content_id) { |aa|
            aa.where((Content_Access.user_group_id == user_id) & (Content_Access.res_type == 'ARTICLE'))
            aa.order_by(Content_Access.changed, :desc)
            aa.limit(amount)
          }
        }
      end
      if [:any, :media_asset].include? res_type then
        result += Media_Asset.select { |a|
          a.join(Content_Access).on(Media_Asset.content_id == Content_Access.content_id) { |aa|
            aa.where((Content_Access.user_group_id == user_id) & (Content_Access.res_type == 'MEDIA_ASSET'))
            aa.order_by(Content_Access.changed, :desc)
            aa.limit(amount)
          }
        }
      end
      return result
      
    end

    def self.before_create(args)
      Content_Access.delete { |aa|
        aa.where((aa.content_id == args[:content_id]) & 
                 (aa.user_group_id == args[:user_group_id]))
      }
    end

  end # class

end # module
end # module

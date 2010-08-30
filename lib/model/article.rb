
require('aurita/model')
Aurita::Main.import_model :content
Aurita::Main.import_model :content_category
Aurita::Main.import_model :content_access
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
    
    def label_string
      title
    end

    def label
      title().to_s
    end

    def self.in_active_time_range
      in_time_range = ((Wiki::Article.time_active_from <= :now) | (Wiki::Article.time_active_from.is_null))
      return (in_time_range & ((Wiki::Article.time_active_to >= :now) | (Wiki::Article.time_active_to.is_null)))
    end
    def in_active_time_range
      in_time_range = (time_active_from.to_s == '' || time_active_from <= Time.now.to_s)
      return in_time_range && (time_active_to.to_s == ''|| time_active_to >= Time.now.to_s)
    end

    expects :title
    expects :tags, Content

    validates :title, :maxlength => 100, :mandatory => true

    add_input_filter(:title) { |v|
      v.gsub("'", "&apos;")
    }

    # Returns true if this article is assigned to a 
    # versioned category. 
    def versioned
      result = false
      categories.each { |c|
        result = result || c.versioned
      }
      return result
    end
    alias is_versioned versioned
    alias is_versioned? versioned

    def readable_id
      title.downcase.gsub(' ','_')
    end

    # Return highest version number of this 
    # article. 
    def max_version
      Article_Version.value_of.max(:version).with(Article_Version.article_id == article_id).to_i
    end

    # Returns part of an article hierarchy. 
    def elements(params={})
      amount   = params[:max]
      amount ||= params[:amount]
      amount ||= :all
      Asset.polymorphic_select { |a|
        a.join(Container).on(Asset.asset_id == Container.asset_id_child) { |c|
          c.where(Container.content_id_parent == content_id)
          c.order_by(Container.sortpos, :asc)
          c.limit(amount)
        } 
      }.to_a
    end
    alias subs elements
    alias parts elements

    def accept_visitor(v)
      v.visit(self)
    end
    
    # Returns Text_Asset instances (paragraphs) of 
    # this article, as array, ordered by their positions. 
    def text_assets(params={})
      amount   = params[:max]
      amount ||= params[:amount]
      amount ||= :all
      Text_Asset.select { |mc|
        mc.join(Container).on(Container.asset_id_child == Text_Asset.asset_id) { |c|
          c.where(Container.content_id_parent == content_id)
          c.order_by(Container.sortpos, :asc)
          c.limit(amount)
        }
      }.to_a
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
      amount ||= :all

      assets = []
      containers = Media_Container.select { |mc|
        mc.join(Container).on(Container.asset_id_child == Media_Container.asset_id) { |c|
          c.where(Container.content_id_parent == content_id)
          c.order_by(Container.sortpos, :asc)
          c.limit(amount)
        }
      }.to_a.map { |mc|
        assets += mc.media_assets
      }
      assets
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

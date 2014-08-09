
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

    def time_active_from
      if attr[:time_active_from].is_a?(String) then
        Date.parse(attr[:time_active_from]) if attr[:time_active_from] != ''
      else
        attr[:time_active_from]
      end
    end
    def time_active_to
      if attr[:time_active_to].is_a?(String) then
        Date.parse(attr[:time_active_to]) if attr[:time_active_to] != ''
      else
        attr[:time_active_to]
      end
    end

    def self.after_active_time_range
      return (Wiki::Article.time_active_to.is_not_null) & (Wiki::Article.time_active_to <= :now) 
    end
    def after_active_time_range
      return (time_active_to.to_s != '' && time_active_to <= Date.today)
    end
    def self.in_active_time_range
      in_time_range = ((Wiki::Article.time_active_from <= :now) | (Wiki::Article.time_active_from.is_null))
      return (in_time_range & ((Wiki::Article.time_active_to >= :now) | (Wiki::Article.time_active_to.is_null)))
    end
    def in_active_time_range
      in_time_range = (time_active_from.to_s == '' || time_active_from <= Date.today)
      return in_time_range && (time_active_to.to_s == ''|| time_active_to >= Date.today)
    end

    expects :title
    expects :tags, Content

    validates :title, :maxlength => 100, :mandatory => true

    html_encode :title, :header

    add_output_filter(:title, :header) { |v|
      v.to_s.gsub('&apos;','`').gsub('"','&quot;')
    }

    add_input_filter(:teaser) { |v|
      v.to_s.gsub("'", %q(\\\'))
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
      title.to_s.downcase.gsub(' ','_')
    end

    # Return highest version number of this 
    # article. 
    def max_version
      Article_Version.value_of.max(:version).with(Article_Version.article_id == article_id).to_i
    end

    def add_partial(partial, params={})
      position = params[:position]
      
      if !position && params[:after_asset] then
        position   = Container.load(:asset_id_child => params[:after_asset]).sortpos + 1
      elsif !position then
        max_offset = Container.value_of.max(:sortpos).where(Container.content_id_parent == content_id)
        max_offset = 0 if max_offset.nil? 
        position = max_offset.to_i+1
      else
        position = position.to_i
      end

      container = Container.create(
                    :content_id_parent => content_id, 
                    :asset_id_child    => partial.asset_id, 
                    :sortpos           => position
                  )
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
    # {{{
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
    end # }}}

    def html_content
      text_assets.map { |t| t.text.to_s }.join('<br /><br />')
    end

    def text_content
      text_asset = text_assets(:amount => 1).first
      text       = text_asset.text if text_asset
      text     ||= ''
      text       = text.gsub(/<[^>]+>/,'').gsub('&nbsp;',' ')
      text
    end
    
    def has_content?
      return text_content.gsub(/\s/,'').length > 0
    end

    def teaser_text(params={})
      length     = params[:length]
      length   ||= 200

      text = teaser

      if text.to_s == '' then
        text_asset = text_assets(:amount => 1).first
        text       = text_asset.text if text_asset
      end
      text ||= ''
      text = text.gsub(/<[^>]+>/,'').gsub('&nbsp;',' ')
      text = text[0..length] unless length == :full
      text = text.split(' ')[0..-2].join(' ')
      text
    end

    def teaser_image
      image = Media_Asset.get(teaser_media_asset_id)
      return image if image
      media_assets(:amount => 1).first
    end

    # Returns Media_Asset instances (paragraphs) of 
    # this article, as array, ordered by their appearance 
    # in the article. 
    # Note that Media_Asset instances can only be part 
    # of an article as part of Media_Container instances: 
    #
    #   Article
    #   |- Text_Asset
    #   |- Text_Asset
    #   |- Media_Container
    #      |- Media_Asset  \
    #      |- Media_Asset   )
    #      |- ...          / \
    #   |- ...                \
    #   |- ...                 )- Returned by article.media_assets
    #   |- Media_Container    /
    #      |- Media_Asset  \ /
    #      |- Media_Asset   ) 
    #      |- ...          /
    #
    def media_assets(params={})
    # {{{
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
        assets += mc.media_assets(params[:filter])
      }
      assets
    end # }}} 

    # Like Article#media_assets, but returns non-image files only. 
    #
    def files(params={})
      filter = Media_Asset.mime.not_ilike('image/%')
      if params[:filter] then
        filter = filter & params[:filter]
      end
      params[:filter] = filter
      media_assets(params)
    end

    # Like Article#media_assets, but returns image files only. 
    #
    def images(params={})
      filter = Media_Asset.mime.ilike('image/%')
      if params[:filter] then
        filter = filter & params[:filter]
      end
      params[:filter] = filter
      media_assets(params)
    end
    
  end 

  Article.prepare_select(:recently_changed, Lore::Type.integer) { |a|
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

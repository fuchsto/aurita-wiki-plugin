
require('aurita')
Aurita.import_module :gui, :autocomplete_result
Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_model :wiki, :media_asset

module Aurita
module Plugins
module Wiki

  class Autocomplete_Controller < Plugin_Controller

    def find_articles(params={})
      return unless params[:keys]
			return unless Aurita.user.category_ids.length > 0
			tags = params[:keys]
			tag  = "%#{tags.join(' ')}%"

      constraints    = Article.title.ilike(tag)
      articles       = Article.find(10).with((Article.has_tag(tags) | Article.title.ilike(tag)) & Article.is_accessible).sort_by(Wiki::Article.article_id, :desc).entities
      article_result = Aurita::GUI::Autocomplete_Result.new()

      key = tags.join(' ')
      articles.each { |a|
        tags  = a.tags.gsub(key, %{<b>#{key}</b>})
        title = a.title.gsub(key, %{<b>#{key}</b>}).gsub(key.capitalize, %{<b>#{key.capitalize}</b>})
        article_result.entries << { :class => :autocomplete_article, 
                                    :id => "Wiki__Article__#{a.article_id}", 
                                    :header => tl(:articles), 
                                    :title => title, 
                                    :informal => tags }
      }
      return article_result
    end
    
    def find_media(params={})
      return unless params[:keys]
			return unless Aurita.user.category_ids.length > 0
			tags = params[:keys]
			tag  = "%#{tags[-1]}%"

			constraints  = Wiki::Media_Asset.deleted == 'f'
      media        = Media_Asset.find(10).with(constraints & 
                                               ((Media_Asset.title.ilike(tags.join(' ')) | Media_Asset.has_tag(tags)) & Media_Asset.accessible)
                                              ).sort_by(Media_Asset.media_asset_id, :desc).entities
      media_result = Aurita::GUI::Autocomplete_Result.new()

      info  = ''
      exten = ''
      media.each { |m|

        thumbnail_string = ''
        inline_image     = ''
        thumb_path = m.fs_path(:size => :tiny)
        if false && File.exists?(thumb_path) then
          File.open(thumb_path, "r") { |t|
            thumbnail_string = t.read
          }
          inline_image = Base64.encode64(thumbnail_string)
          "<img src=\"data:image/jpg;base64, \n#{inline_image}\" />"
        end

        exten = m.media_asset_id
        exten = m.mime_extension unless m.has_preview? 
        info = ''
        info = '<b>' << m.title.to_s << '</b><br />' 
        info << m.tags.to_s 
        entry = '<div style="height: 70px; width: 70px; text-align: center; background-color: #cccccc; float: left; ">' << m.icon(:tiny) + '</div>
                 <div style="float: left; color: #555555; margin-left: 4px; width: 320px; overflow: hidden; ">' << info.to_s +  '</div>'

        media_result.entries << { :class => :autocomplete_image, 
                                  :id => "Wiki__Media_Asset__#{m.media_asset_id}", 
                                  :element => entry, 
                                  :header => tl(:media) }
      }
      return media_result
    end

  end

end
end
end


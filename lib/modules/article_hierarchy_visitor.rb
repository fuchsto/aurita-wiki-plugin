
require 'aurita'
Aurita.import_plugin_model :wiki, :article_version
Aurita.import_plugin_module :wiki, :article_visitor

def pg_prep(binstr)
  binstr.split(//).map { |char|
    case char[0]
    when (0..31),39,92,(127..255)
      "\\#{sprintf("%03o", char[0])}"
    else
      char
    end
  }.join
end

module Aurita
module Plugins
module Wiki

    class Article_Hierarchy_Visitor < Article_Visitor

      attr_reader :hierarchy
      
      def initialize
        @hierarchy = {}
      end

      def visit_article(article)
        @hierarchy[article.content_id] = { :article => { :article_id => article.article_id, 
                                                         :title => article.title, 
                                                         :tags => article.tags, 
                                                         :deleted => article.deleted, 
                                                         :locked => article.locked } }
        @hierarchy[article.content_id][:text_assets] = [] 
        article.subs[:text_assets].each { |text_asset| 
          # Stuff
          @hierarchy[article.content_id][:text_assets] << text_asset.accept_visitor(self)
        }
        return @hierarchy
      end

      def visit_text_asset(text_asset)
        result = { :text_asset => text_asset.text.to_s.gsub('"','\"') } 
        subs = text_asset.subs
        result[:media_assets] = []
        subs[:media_assets].each { |media_asset| 
          result[:media_assets] << media_asset.accept_visitor(self)
        }
# TODO: Change to: 
#       subs.keys.each { |key| 
#         subs[key].each { |sub| 
#           result[key] << sub.accept_visitor(self)
#         }
#        }
        result[:todo_asset] = subs[:todo_assets]
        form_asset = subs[:form_asset]
        if form_asset then
          form = form_asset.accept_visitor(self)
          cid = form_asset.attr[:content_id]
          result[cid] = form
        end
        return result
      end

      def visit_media_asset(media_asset)
        media_asset.media_asset_id
      end

      def visit_form_asset(form_asset)
        form_asset.form_asset_id
      end

      def visit_todo_asset(todo_asset)
        todo_asset.todo_asset_id
      end
      
    end
    

end
end
end


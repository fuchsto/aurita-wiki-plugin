
require 'aurita'
Aurita.import_plugin_model :wiki, :article_version
Aurita.import_plugin_module :wiki, :article_hierarchy_visitor

module Aurita
module Plugins
module Wiki

    class Article_Full_Hierarchy_Visitor < Article_Hierarchy_Visitor

      attr_reader :hierarchy
      
      def initialize
        @hierarchy = {}
      end

      def visit_article(article)
        result = super(article)
        result.values.first[:instance] = article
        result
      end
      
      def visit_text_asset(text_asset)
        result = { :text_asset => text_asset }
        subs = text_asset.subs
        result[:media_assets] = []
        subs[:media_assets].each { |media_asset| 
          result[:media_assets] << media_asset.accept_visitor(self)
        }
        result[:todo] = subs[:todo_asset].accept_visitor(self) if subs[:todo_asset]
        form_asset = subs[:form_asset]
        if form_asset then
          form = form_asset.accept_visitor(self)
          result[:form] = form
        end
        return result
      end

      def visit_media_asset(media_asset)
        media_asset
      end

      def visit_form_asset(form_asset)
        form_asset
      end
      
      def visit_todo_asset(todo_asset)
        todo_asset
      end
      
    end
    
end
end
end



require 'aurita'
Aurita.import_plugin_module :wiki, :article_visitor
Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_model :wiki, :text_asset
Aurita.import_plugin_model :wiki, :media_asset
# Aurita.import_plugin_model :wiki, :form_asset


module Aurita
module Plugins
module Wiki

    class Article_Visitor

      def visit_article(article)
      end

      def visit_text_asset(text_asset)
      end

      def visit_media_asset(media_asset)
      end

      def visit_form_asset(form_asset)
      end
      
    end
    
end
end
end


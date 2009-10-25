
require 'aurita'
Aurita.import('base/plugin_register')
Aurita.import_plugin_model :wiki, :article_version
Aurita.import_plugin_module :wiki, :article_visitor

module Aurita
module Plugins
module Wiki

    class Article_Hierarchy_Visitor < Article_Visitor

      attr_reader :hierarchy
      
      def initialize(article)
        @hierarchy = {}
        visit_article(article)
      end
      
      private
      
      def visit_article(article)
        @hierarchy = { :meta => { :article_id   => article.article_id, 
                                  :content_id   => article.content_id, 
                                  :version      => article.latest_version_number, 
                                  :title        => article.title, 
                                  :tags         => article.tags, 
                                  :deleted      => article.deleted, 
                                  :category_ids => article.category_ids, 
                                  :locked       => article.locked } 
        }
        @hierarchy[:parts] = [] 
        article.parts.each { |part| 
          @hierarchy[:parts] << part.accept_visitor(self)
        }
        return @hierarchy
      end
      
      public
      
      def visit(part)
        return Aurita::Plugin_Register.get(Hook.wiki.article.hierarchy.part, :part => part)
      end

    end

end
end
end


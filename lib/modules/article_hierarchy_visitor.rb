
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
        @article   = article
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
          @hierarchy[:parts] << part.accept_visitor(self) if part
        }
        return @hierarchy
      end
      
      public
      
      def visit(part)
        node = { :id => part.key, :model => part.class.to_s }
      end

    end

end
end
end


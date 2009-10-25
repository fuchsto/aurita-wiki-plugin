
require 'aurita'
Aurita.import_plugin_model :wiki, :article_version
Aurita.import_plugin_module :wiki, :article_hierarchy_visitor

module Aurita
module Plugins
module Wiki

    class Article_Full_Hierarchy_Visitor < Article_Hierarchy_Visitor

      attr_reader :hierarchy
      
      def initialize(article)
        super(article)
      end

      def visit_article(article)
        super(article)
        @hierarchy[:instance] = article

        return @hierarchy
      end
      
      def visit(part)
        result = super(part)
        result[:part_entity] = part
      end
      
    end
    
end
end
end


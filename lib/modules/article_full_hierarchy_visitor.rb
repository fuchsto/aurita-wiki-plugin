
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
        @hierarchy[:instance] = article
      end

      def visit(part)
        node            = super(part)
        node[:instance] = part
        return node
      end
      
    end
    
end
end
end


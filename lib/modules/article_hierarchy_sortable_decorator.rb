
require('aurita/controller')
Aurita.import_plugin_module :wiki, :article_hierarchy_default_decorator
Aurita.import_plugin_model :form_generator, :model_register

module Aurita
module Plugins
module Wiki

  class Article_Hierarchy_Sortable_Decorator < Article_Hierarchy_Default_Decorator 
  include Aurita::GUI::Helpers
  extend Aurita::GUI::Helpers
  include Aurita::GUI

    attr_accessor :hierarchy
    attr_reader :viewparams
    
    def initialize(hierarchy, templates={})
      super(hierarchy, templates.update(:article => :article_sortable_decorator))
    end

    def decorate_part(part, article)
      part_entity      = part[:instance]

      HTML.li(:id => "partials_#{part_entity.asset_id}", :class => [ :no_bullets, :sortable ] ) { 
        HTML.div(:class => :article_text) { 
          Plugin_Register.get(Hook.wiki.article.hierarchy.partial, 
                              :article => article, 
                              :part    => part_entity) 
        }
      }
    end

  end

end
end
end


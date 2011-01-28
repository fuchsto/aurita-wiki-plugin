
require('aurita-gui/widget')
require('aurita/plugin_controller')
require('enumerator')

Aurita.import :base, :plugin_methods


module Aurita
module Plugins
module Wiki
module GUI

  # Decorator for a given article partial GUI element. 
  #
  class Article_Partial < Aurita::GUI::Widget

    def initialize(params={}, &block)
      @article        = params[:article]
      @partial_entity = params[:partial_entity]
      @partial        = params[:partial]
      @partial      ||= yield if block_given?
      raise ::Exception.new("No parameter :partial given for Article_Partial") unless @partial
      super()
    end

    def element
      
      tce = HTML.div.article_text { 
        @partial
      }

      sort_btn = HTML.div(:class => [ :context_menu_button, :sort_handle ]) { 
        HTML.img(:src => '/aurita/images/icons/sort.gif')
      } 

      asset_id   = @partial_entity.asset_id if @partial_entity
      asset_id ||= :new

      if @partial_entity && Aurita.user.may_edit_content?(@article) then
        container_params = { :content_id_parent => @article.content_id, 
                             :asset_id_child    => asset_id, 
                             :article_id        => @article.article_id}
        context_buttons = []
        context_buttons = @partial.context_buttons if @partial.respond_to?(:context_buttons)
        context_buttons << sort_btn
      
        tce = Context_Menu_Element.new(tce, 
                                       :entity              => @partial_entity, 
                                       :id                  => "article_part_asset_#{@partial_entity.asset_id}_contextual", 
                                       :show_button         => true, 
                                       :add_context_buttons => context_buttons, 
                                       :class               => :article_contextual_partial, 
                                     # :type                => part[:model].gsub('Aurita::Plugins::',''), 
                                       :params              => container_params)
        tce += Partial_Divide.new(:partial => @partial_entity, 
                                  :params  => container_params).string
      end
      HTML.div.article_partial(:id => "article_part_asset_#{asset_id}") { 
        tce
      }
    end

  end # class Article_Partial

  class Partial_Divide < Aurita::GUI::Element
  include Aurita::GUI
  include Aurita::Plugin_Methods
  include Aurita::GUI::Link_Helpers
  include Aurita::GUI::I18N_Helpers

    def initialize(params={})
      @params    = params
      super()
    end

    def string
      partial = @params[:partial]
      article = partial.article
      div_buttons = HTML.div(:class => [ :context_menu_button, :sort_handle ]) { 
        link_to(:controller  => 'Wiki::Text_Asset', 
                :action      => :perform_add, 
                :after_asset => partial.asset_id, 
                :content_id  => article.content_id) { 
          HTML.img(:src => '/aurita/images/icons/context_add_text_partial.gif') + 
          HTML.span.label { tl(:add_text_partial) }  
        }
      } + HTML.div(:class => [ :context_menu_button, :sort_handle ]) { 
        link_to(:controller  => 'Wiki::Media_Container', 
                :action      => :perform_add, 
                :after_asset => partial.asset_id, 
                :content_id  => article.content_id) { 
          HTML.img(:src => '/aurita/images/icons/context_add_files_partial.gif') + 
          HTML.span.label { tl(:add_files_partial) }
        }
      } 
      
      partial_divide_dom_id = "article_#{article.article_id}_part_#{partial.asset_id}"
      partial_dom_id        = "article_part_asset_#{partial.asset_id}"
      
      plugin_get(Aurita::Hook.wiki.article.add_partial_type, 
                 :partial        => partial, 
                 :divider_dom_id => partial_divide_dom_id, 
                 :partial_dom_id => partial_dom_id,
                 :article        => article).each { |component|
        component.add_css_class(:context_menu_button, :sort_handle)
        div_buttons << component
      }
      
      HTML.div.article_partial_divide(:id => partial_divide_dom_id) { 
        Context_Menu_Element.new(:show_button     => true, 
                                 :context_buttons => div_buttons, 
                                 :entity          => partial, 
                                 :type            => 'Wiki::Container', 
                                 :params          => @params[:params]) {
          HTML.div.field { HTML.hr }
        }
      }.string
    end

  end # class Partial_Divide

end # GUI
end # Wiki
end # Plugins
end # Aurita


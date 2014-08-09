
require('aurita-gui/widget')

module Aurita
module Plugins
module Wiki
module GUI

  class Article_Selection_List_Entry < Aurita::GUI::Widget

    def initialize(params={})
      @params     = params
      @article    = params[:article]
      @article_id = params[:article_id] || @article.article_id
      @label      = params[:label] || @article.title
      
      @params[:name] ||= 'article_ids'
      @hidden_name   ||= "#{params[:name]}[]"
      
      super()
      
      add_css_class(:article_selection_list_entry)
    end

    def element
      random_id = "article_selection_list_entry_#{@article_id}_#{rand(1000)}"
      HTML.li(:id => random_id) { 
        HTML.div { 
          HTML.a.icon(:onclick => "$('#{random_id}').remove();") {
            HTML.img.icon(:src => '/aurita/images/icons/delete_small.png') 
          } + 
          @label
        } + 
        HTML.input(:type => :hidden, :name => "#{@hidden_name}", :value => @article_id) 
      }
    end

  end

end
end
end
end


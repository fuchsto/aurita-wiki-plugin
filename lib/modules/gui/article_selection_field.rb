
require('aurita-gui/widget')

module Aurita
module Plugins
module Wiki
module GUI

  class Article_Selection_Field < Aurita::GUI::Widget

    def initialize(params={})
      @attrib = params
      @attrib[:id]   = 'article' unless @attrib[:id]
      @attrib[:name] = 'article' unless @attrib[:name]
      @key           = params[:key]
      @key         ||= :content_id
      super()
    end

    def element
      HTML.div { 
        HTML.ul(:id => "#{@attrib[:id]}_selection") { } + 
        GUI::Input_Field.new(@attrib) + 
        HTML.div.autocomplete(:id    => "#{@attrib[:id]}_choices", 
                              :style => 'position: relative !important;') { } 
      }
    end

    def js_initialize()
      input_id     = @attrib[:id]
      choices_id   = "#{input_id}_choices"
      selection_id = "#{input_id}_selection"

code = <<JS
      new Ajax.Autocompleter("#{input_id}", 
                             "#{choices_id}", 
                             "/aurita/poll", 
                             { 
                               minChars: 2, 
                               updateElement: function(li) { 
                                 $('#{selection_id}').innerHTML = '<li>'+li.innerHTML+'<input type="hidden" name="content_id" value="'+li.id+'" /></li>';
                               } , 
                               frequency: 0.1, 
                               tokens: [], 
                               parameters: 'controller=Wiki::Autocomplete&action=all_articles&pkey=#{@key}&mode=none'
                             }
      );
JS
    end

  end

end
end
end
end


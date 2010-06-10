
require('aurita-gui/form/form_field')

module Aurita
module Plugins
module Wiki
module GUI

  class Article_Select_Field < Aurita::GUI::Form_Field
  include Aurita::GUI

    def initialize(params={}, &block)
      @attrib = params
      @attrib[:id]   = 'article' unless @attrib[:id]
      @attrib[:name] = 'article' unless @attrib[:name]
      @num_results   = @attrib[:num_results]
      @key           = params[:key]
      @key         ||= :content_id
      @num_results ||= 10
      add_css_class(:search)
      if @attrib[:value].respond_to?(:pkey) && @attrib[:value].respond_to?(:label) then
        @value         = @attrib[:value].pkey
        @option_label  = @attrib[:value].label
      else
        @value         = @attrib[:value]
        @option_label  = @attrib[:option_label]
      end
      super(params, &block)
      @attrib.delete(:value)
      @attrib.delete(:option_label)
    end

    def element
      HTML.div { 
        HTML.ulist(:id => "#{@attrib[:id]}_selection") { selected_entry } + 
        GUI::Input_Field.new(@attrib).decorated_element + 
        HTML.div.autocomplete(:id    => "#{@attrib[:id]}_choices", 
                              :style => 'position: relative !important;') { } 
      }
    end

    private

    def selected_entry
      HTML.li { @option_label + HTML.input(:type => :hidden, :name => @key, :value => @value).decorated_element } if @value && @option_label
    end

    public

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
                                 $('#{selection_id}').innerHTML = '<li>'+li.innerHTML+'<input type="hidden" id="#{@attrib[:id]}_id" name="#{@key}" value="'+li.id+'" /></li>';
                                 $('#{input_id}').value = ''; 
                               } , 
                               frequency: 0.1, 
                               tokens: [], 
                               parameters: 'controller=Wiki::Autocomplete&field=#{@attrib[:name]}&action=all_articles&pkey=#{@key}&num_results=#{@num_results}&mode=none'
                             }
      );
JS
    end

  end

end
end
end
end


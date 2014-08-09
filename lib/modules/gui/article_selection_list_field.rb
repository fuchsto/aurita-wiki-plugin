
require('aurita-gui/form/form_field')

module Aurita
module Plugins
module Wiki
module GUI

  class Article_Selection_List_Field < Aurita::GUI::Form_Field
  include Aurita::GUI

    def initialize(params={}, &block)
      @attrib = params
      @attrib[:id]   = 'article_ids' unless @attrib[:id]
      @attrib[:name] = 'article_ids' unless @attrib[:name]
      @hidden_name ||= "#{params[:name]}[]"
      @num_results   = @attrib[:num_results]
      @key           = params[:key]
      @key         ||= :article_id
      @num_results ||= 10
      
      @row_action  ||= params[:row_action]
      @row_action  ||= 'Wiki::Article/selection_list_choice'
      
      add_css_class(:search)
      
      @value = params[:value]

      @dom_id = @attrib[:id]

      super(params, &block)

      @attrib.delete(:value)
      @attrib.delete(:option_label)
    end

    def element
      input_attrib = @attrib.dup
      input_attrib[:name] = "#{@attrib[:name]}_input"

      HTML.div { 
        HTML.ulist(:id => "#{@attrib[:id]}_selection") { selected_entry } + 
        GUI::Input_Field.new(input_attrib).decorated_element + 
        HTML.div.autocomplete(:id    => "#{@attrib[:id]}_choices", 
                              :style => 'position: relative !important;') { } 
      }
    end

    private

    def selected_entry
      articles   = Wiki::Article.find(:all).with(Wiki::Article.article_id.in(@value)).to_a if @value.is_a? Array
      articles ||= []
      articles.map { |a|
        entry_dom_id = "#{@dom_id}_#{a.article_id}"

        Article_Selection_List_Entry.new(:article => a, :name => @attrib[:name])
      }
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
                                 Aurita.get_remote_string(
                                    'Wiki::Article/selection_choice/name=#{@attrib[:name]}&article_id=' + li.id, 
                                    function(resp) { 
                                      var elem = document.createElement('span');
                                      elem.innerHTML = resp; 
                                      $('#{selection_id}').appendChild(elem);
                                    }, 
                                    'GET' );

                                 $('#{input_id}').value = ''; 
                               }, 
                               frequency: 0.1, 
                               tokens: [], 
                               parameters: 'controller=Wiki::Autocomplete&field=#{@attrib[:name]}_input&action=all_articles&pkey=#{@key}&num_results=#{@num_results}&mode=none'
                             }
      );
JS
    end

  end

end
end
end
end


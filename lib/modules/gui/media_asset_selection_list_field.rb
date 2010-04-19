
require('aurita-gui/widget')
Aurita.import_plugin_module :wiki, :gui, :media_asset_selection_field

module Aurita
module Plugins
module Wiki
module GUI

  # Configures Media_Asset_Selection_Field for selection of multiple 
  # media assets. 
  #
  class Media_Asset_Selection_List_Field < Media_Asset_Selection_Field
  include Aurita::GUI 

    def initialize(params={}, &block)
      @attrib = params
      @attrib[:id]   = 'media_asset_ids' unless @attrib[:id]
      @attrib[:name] = 'media_asset_ids' unless @attrib[:name]
      @key           = params[:key] || :content_id
      @selected      = params[:value] 
      @selected    ||= {}
      @row_action    = 'Wiki::Media_Asset/selection_list_choice'

      params.delete(:value)
      super(params, &block)
      add_css_class(:search)
    end

    def element

      choices_id = "#{@attrib[:id]}_choices"
      list_id    = "#{@attrib[:id]}_selected"
      input_id   = @attrib[:id].dup + '_text'

      onfocus    = "$('#{choices_id}').show();"
      onblur     = "$('#{choices_id}').hide();"
      onkeyup    = "Aurita.load({ action: '#{@row_action}/list_id=#{list_id}&variant=#{@variant}&key='+$('#{input_id}').value, 
                                  element: '#{@attrib[:id]}_choices', 
                                  onload: function() { #{onfocus} }, 
                                  silently: true });"

      field_params = @attrib.update(:onkeyup => onkeyup, 
                                    :name    => input_id, 
                                    :id      => input_id) 

      HTML.div {
        HTML.ulist(:id => list_id) { 
          entries = []
          @selected.each_pair { |k,v|
            entries << Media_Asset_Selection_List_Entry.new(:media_asset_id => k, :name => @attrib[:name], :label => v)
          }
          entries
        } + 
        GUI::Input_Field.new(field_params) + 
        HTML.div(:id    => choices_id, 
                 :class => :media_asset_list, 
                 :style => 'display: none;') {
          
        }
      }
    end

  end

end
end
end
end



require('aurita-gui/form/form_field_widget')

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_Selection_Field < Aurita::GUI::Form_Field_Widget
  include Aurita::GUI 

    def initialize(params={}, &block)
      params[:name] = 'media_asset' unless params[:name]
      params[:id]   = params[:name] unless params[:id]
      @key         ||= params[:key] || :content_id
      @variant     ||= params[:variant] || :thumb
      @row_action  ||= params[:row_action]
      @row_action  ||= 'Wiki::Media_Asset/selection_choice'
      @value       ||= params[:value] 
      @value       ||= {}
      @hidden_name ||= params[:name]

      super(params, &block)
      add_css_class(:search)
    end

    def form_field
      return @form_field if @form_field
      
      choices_id = "#{@attrib[:id]}_choices"
      list_id    = "#{@attrib[:id]}_selected"
      input_id   = @attrib[:id].to_s.dup + '_text'

      onfocus    = "$('#{choices_id}').show();"
      onblur     = "$('#{choices_id}').hide();"
      key_value  = "$('#{input_id}').value"
      onkeyup    = "Aurita.load({ action: '#{@row_action}/name=#{@hidden_name}&list_id=#{list_id}&variant=#{@variant}&key='+#{key_value}, 
                                  element: '#{@attrib[:id]}_choices', 
                                  method: 'POST', 
                                  onload: function() { #{onfocus} }, 
                                  silently: true });"

      field_params = @attrib.dup
      field_params.update(:onkeyup => onkeyup, 
                          :name    => input_id, 
                          :id      => input_id) 
      field_params.delete(:value)

      @form_field = GUI::Input_Field.new(field_params)
      
      @form_field
    end
    
    def element

      # If list of media_asset_ids has been passed, resolve 
      # actual instances and their title: 
      if !@value.is_a?(Hash) then
        entities = {}
        m = Wiki::Media_Asset.select { |m|
          m.where(m.media_asset_id == (@value))
        }.first
        if m then
          entities[m.media_asset_id] = m.title
          @value = entities
        else
          @value = {}
        end
      end

      choices_id = "#{@attrib[:id]}_choices"
      list_id    = "#{@attrib[:id]}_selected"
      
      HTML.div {
        HTML.ulist(:id => list_id) { 
          entries = []
          @value.each_pair { |k,v|
            entries << Media_Asset_Selection_List_Entry.new(:media_asset_id => k, :name => @hidden_name, :label => v)
          }
          entries
        } + 
        form_field().decorated_element + 
        HTML.div(:id    => choices_id, 
                 :class => :media_asset_list, 
                 :style => 'display: none;') {
          
        }
      }
    end

    def js_initialize
      ''
    end

  end

end
end
end
end


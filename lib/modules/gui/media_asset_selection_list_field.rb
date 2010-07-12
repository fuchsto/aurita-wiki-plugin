
require('aurita-gui/widget')
Aurita.import_plugin_module :wiki, :gui, :media_asset_selection_field
Aurita.import_plugin_module :wiki, :gui, :media_asset_selection_list_entry

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
      params[:id]    = 'media_asset_ids' unless params[:id]
      params[:name]  = 'media_asset_ids' unless params[:name]
      params[:name]  = params[:name].to_s
      @key         ||= params[:key] || :content_id
      @row_action  ||= params[:row_action]
      @row_action  ||= 'Wiki::Media_Asset/selection_list_choice'
      @value       ||= params[:value] 
      @value       ||= {}
      @hidden_name ||= "#{params[:name]}[]"

      super(params, &block)

      add_css_class(:search)
    end

    def element

      # If list of media_asset_ids has been passed, resolve 
      # actual instances and their title: 

      if @value.is_a?(Array) then
        entities = {}
        Wiki::Media_Asset.select { |m|
          m.where(m.media_asset_id.in(@value))
        }.each { |m|
          entities[m.media_asset_id] = m.title
        }
        @value = entities
      end

      choices_id = "#{@attrib[:id]}_choices"
      list_id    = "#{@attrib[:id]}_selected"
      input_id   = @attrib[:id].dup + '_text'

      HTML.div {
        HTML.ulist(:id => list_id) { 
          entries = []
          @value.each_pair { |k,v|
            entries << Media_Asset_Selection_List_Entry.new(:media_asset_id => k, :name => "#{@hidden_name}", :label => v)
          }
          entries
        } + 
        form_field.decorated_element + 
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


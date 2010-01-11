
require('aurita-gui/widget')

module Aurita
module Plugins
module Wiki
module GUI

  class Media_Asset_Selection_Field < Aurita::GUI::Form_Field
  include Aurita::GUI 

    def initialize(params={}, &block)
      @attrib = params
      @attrib[:id]   = 'media_asset' unless @attrib[:id]
      @attrib[:name] = 'media_asset' unless @attrib[:name]
      @key           = params[:key]
      @key         ||= :content_id
      super(params, &block)
    end

    def element
      onkeyup = "Aurita.load({ action: 'Wiki::Media_Asset/editor_list_choice/key='+$('#{@attrib[:id]}').value, 
                               element: '#{@attrib[:id]}_choices', 
                               silently: true });"
      field_params = { :name    => @attrib[:name], 
                       :id      => @attrib[:id], 
                       :onkeyup => onkeyup }
      HTML.div {
        GUI::Input_Field.new(field_params) + 
        HTML.div(:id => "#{@attrib[:id]}_choices", :class => :media_asset_list) {
          
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

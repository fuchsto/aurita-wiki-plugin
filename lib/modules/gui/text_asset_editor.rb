
require('aurita-gui/widget')
Aurita.import_plugin_model :wiki, :text_asset


module Aurita
module Plugins
module Wiki
module GUI

  class Text_Asset_Editor < Aurita::GUI::Widget
  include Aurita::GUI

    def initialize(params={})
      @params        = params
      @text_asset    = params[:text_asset]
      if @text_asset then
        @text_asset_id = @text_asset.text_asset_id
        @text          = @text_asset.text
        @mode          = :update
      else
        @text_asset_id = :new
        @text          = ''
        @mode          = :add
      end
      if @params[:article] 
        @article_id = @params[:article].article_id
      end
      super()
    end

    def element
      form_dom_id      = "text_asset_#{@mode}_form_#{@text_asset_id}"
      container_dom_id = "text_asset_#{@mode}_container_#{@text_asset_id}"
      action           = :perform_add if @mode = :add
      action           = :perform_update if @mode = :update

      HTML.div.text_asset_editor_container { 
        
        HTML.form(:id => form_dom_id, :name => form_dom_id) { 
          Hidden_Field.new(:name => :controller,    :value => 'Wiki::Text_Asset') + 
          Hidden_Field.new(:name => :action,        :value => action) + 
          Hidden_Field.new(:name => :text_asset_id, :value => @text_asset_id) + 
          Hidden_Field.new(:name => :article_id,    :value => @article_id) + 
          Hidden_Field.new(:name => :after_asset,   :value => @params[:after_asset]) + 

          HTML.div.text_asset_editor(:id => :text_asset_form) {
            HTML.div.container_inline_editor_button_bar { 
              Text_Button.new(:icon    => :editor_save, 
                              :class   => :no_border, 
                              :onclick => Javascript.Aurita.submit_form(form_dom_id)) + 
              Text_Button.new(:icon    => :editor_close, 
                              :class   => :no_border, 
                              :onclick => "$('#{container_dom_id}').hide(); Aurita.Editor.save_all()") +
              HTML.div(:style => 'clear: both;') { } 
            } + 

            HTML.textarea(:name  => "public.text_asset.text", 
                          :class => [ :fullwidth, :full, :editor ], 
                          :style => 'width: 100%; clear: both;', 
                          :id    => "lore_textarea_#{@text_asset_id}") { @text }
          }
        }
    
      }
    end

    def js_initialize
      "Aurita.Editor.init_all();"
    end

  end

end
end
end
end



require('aurita/controller')
Aurita.import_plugin_model :wiki, :text_asset
Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_controller :wiki, :media_asset
Aurita.import_plugin_controller :wiki, :text_asset

module Aurita
module Plugins
module Wiki

  class Container_Controller < Plugin_Controller

    def perform_add
    end

    def perform_update
      Text_Asset_Controller.new(@params).perform_update()
      text_asset = load_instance(Text_Asset)

      # delete previous attached media assets
      Container.delete { |c|
        c.where((c.content_type == 'IMAGE') & (c.content_id_parent == param(:content_id)))
      }
      max_offset = Container.value_of.max(:sortpos).where(Container.content_id_parent == param(:content_id_parent))
      max_offset = 0 if max_offset.nil? 
      sortpos = max_offset.to_i+1

      marked_image_register = param(:marked_image_register).to_s.split('_') 
      marked_image_register.uniq!
      marked_image_register.each { |content_id|
        if content_id.to_i != 0 then
        sortpos += 1
        Container.create(:content_id_child => content_id, 
                         :content_type => 'IMAGE', 
                         :sortpos => sortpos, 
                         :content_id_parent => text_asset.content_id)
        end
      }
    end

    def perform_delete

      # Load container itself
      container = load_instance()

      Content.touch(container.content_id_parent, 'DELETE:Container')

      # Load text asset in container
      asset = Asset.find(1).with(Asset.asset_id == container.asset_id_child).polymorphic.entity
      
      exec_js("Element.hide('article_part_asset_#{asset.asset_id}'); ")

      # Delete text asset
      asset.delete
      # Delete container itself
      container.delete
    end

    def add
      container_types = [ 
        HTML.a(:class => :icon, 
               :onclick => link_to(:action     => :perform_add, 
                                   :controller => 'Wiki::Text_Asset', 
                                   :element    => :context_menu, 
                                   :content_id => param(:content_id))) { 
          HTML.img(:src => '/aurita/images/icons/context_add_container.gif') + HTML.span() { tl(:text_partial) }
        }, 
        HTML.a(:class => :icon, 
               :onclick => link_to(:action     => :perform_add, 
                                   :controller => 'Wiki::Media_Container', 
                                   :element    => :context_menu, 
                                   :content_id => param(:content_id))) { 
          HTML.img(:src => '/aurita/images/icons/context_add_container.gif') + HTML.span() { tl(:files_partial) }
        }, 
      ]
      container_types += plugin_get(Hook.wiki.container.types, :content_id_parent => param(:content_id), 
                                                               :article_id        => param(:article_id))
      render_view(:container_form, :types => container_types)
    end

    def delete
      form        = delete_form(Container)
      form.fields = [ Container.content_id_parent, Container.asset_id_child ]
      form.add_hidden(Container.content_id_parent => param(:content_id_parent))
      form.add_hidden(Container.asset_id_child    => param(:asset_id_child))
      HTML.div { 
        HTML.div(:class => [ :message_box, :confirmation ]) { tl(:delete_this_article_partial) } + 
        decorate_form(form)
      } 
    end
    
  end

end
end
end


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
      
      if param(:text).to_s == '' and param(:custom_model_name).to_s == '' and param(:marked_image_register).to_s == ''
        return
      end

      @params['text'] = ' ' if param(:text).to_s == ''
      text_asset = Text_Asset_Controller.new(@params).perform_add()

      max_offset = Container.value_of.max(:sortpos).where(Container.content_id_parent == param(:content_id))
      max_offset = 0 if max_offset.nil? 
      sortpos = max_offset.to_i+1

=begin
      if(form_asset) then
        Container.create(:content_id_child => form_asset.content_id, 
                         :content_type => 'FORM', 
                         :sortpos => sortpos, 
                         :content_id_parent => text_asset.content_id)
        sortpos += 1
      end
=end
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

    def perform_add_media_asset
      max_offset = Container.value_of.max(:sortpos).where(Container.content_id_parent == param(:content_id_parent))
      max_offset = 0 if max_offset.nil? 
      sortpos = max_offset.to_i+1

      Container.create(:content_id_child => param(:content_id_child), 
                       :content_type => 'IMAGE', 
                       :sortpos => sortpos, 
                       :content_id_parent => param(:content_id_parent))
    end
    
    def perform_delete_media_asset
      Container.delete { |c|
        c.where((c.content_id_parent == param(:content_id_parent)) & 
                (c.content_id_child == param(:content_id_child)))
        c.limit(1)
      }
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

      Content.touch(container.content_id_parent, 'DELETE:CONTAINER')

      # Load text asset in container
      asset = Asset.find(1).with(Asset.asset_id == container.asset_id_child).polymorphic.entity
      
      exec_js("Element.hide('article_part_asset_#{asset.asset_id}'); ")

      # Delete text asset
      asset.delete
      # Delete container itself
      container.delete
    end

    def edit_attachments
      container    = Container.find(1).with((Container.content_id_parent == param(:content_id_parent)) & 
                                            (Container.content_id_child == param(:content_id_child))).entity
      text_asset   = Text_Asset.find(1).with(Text_Asset.content_id == param(:content_id_child)).entity
      media_assets = Media_Asset.select { |ma| 
        ma.where(Media_Asset.content_id.in(Container.select(:content_id_child) { |cid| 
            cid.where(Container.content_id_parent == param(:content_id_child))
          })
        )
      }.to_a

      render_view(:container_attachments, 
                  :article => text_asset.parent_article, 
                  :container => container, 
                  :text_asset => text_asset, 
                  :media_asset_list => Media_Asset_Controller.choice_list(:selected => media_assets))
    end
    
    def perform_edit_attachments

      text_asset = Text_Asset.load(:text_asset_id => param(:text_asset_id))
      text_asset.parent_article.touch
      marked_image_register = param(:marked_image_register).to_s.split('_') 
      marked_image_register.uniq!
      sortpos = 0
      text_asset.parent_article.touch
      Container.delete { |c| 
        c.where((Container.content_id_parent == text_asset.content_id) &
                (Container.content_type == 'IMAGE'))
      }
      param(:selected_media_assets, []).each { |content_id|
        if content_id.to_i != 0 then
        sortpos += 1
        Container.create(:content_id_child => content_id, 
                         :content_type => 'IMAGE', 
                         :sortpos => sortpos, 
                         :content_id_parent => text_asset.content_id)
        end
      }
      redirect_to(:controller => 'Wiki::Article', :article_id => text_asset.article.article_id)
    end

    def add
      container_types = [ 
        HTML.a(:class => :icon, 
               :onclick => link_to(:action     => :perform_add, 
                                   :controller => 'Wiki::Text_Asset', 
                                   :element    => :context_menu, 
                                   :content_id => param(:content_id))) { 
          HTML.img(:src => '/aurita/images/icons/context_add_container.gif') + HTML.span() { 'Text' }
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

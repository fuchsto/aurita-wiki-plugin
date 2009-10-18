
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

      Content.touch(container.content_id_parent, 'DELETE:TEXT')

      # Load text asset in container
      text_asset = Text_Asset.load(:content_id => container.content_id_child)
      # Delete media assets in text asset
      Container.delete { |ma|
        ma.where(Container.content_id_parent == text_asset.content_id)
      }
      
      exec_js("Element.hide('container_#{text_asset.content_id}'); ")

      # Delete text asset
      text_asset.delete
      # Delete container itself
      container.delete

    end

    def add_text
      
      @params[:text] = tl(:text_asset_blank_text)
      @params[:tags] = 'text_asset'
      text_asset = Text_Asset_Controller.new(@params).perform_add()
      text_asset[:display_text] = tl(:text_asset_blank_text)
      text_asset.commit
      text_asset_id     = text_asset.text_asset_id
      content_id_child  = text_asset.content_id
      content_id_parent = param(:content_id)
      article = Article.find(1).with(Article.content_id == param(:content_id)).entity
      article.touch

      redirect_to(article, :action => :show, 
                           :edit_inline_content_id => text_asset.content_id, 
                           :edit_inline_type => 'TEXT_ASSET')

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
        HTML.a(:onclick => link_to(:action     => :add_text, 
                                   :element    => :context_menu, 
                                   :content_id => param(:content_id))) { 
          HTML.img(:src => '/aurita/images/icons/context_add_container.gif') + HTML.span() { 'Text' }
        }, 
      ]
      container_types += plugin_get(Hook.wiki.container.types, :article_content_id => param(:content_id))
      render_view(:container_form, :types => container_types)
    end

    def update

      text_asset = load_instance(Text_Asset)

      pre_select_media_assets = Media_Asset.select { |ma|
        ma.where(Media_Asset.content_id.in(
            Container.select(Container.content_id_child) { |cid|
              cid.where(cid.content_id_parent == param(:content_id_child))
            })
        )
      }
      
      media_list = Media_Asset_Controller.choice_list(:selected => pre_select_media_assets, 
                                                      :text_asset => text_asset)
      text_asset_form = update_form(Text_Asset)
      text_asset_form.add_hidden(:cb__model, 'Wiki::Container')
      text_asset_form.add_hidden(:cb__controller, 'perform_update')
      text_asset_form.add_hidden(Text_Asset.text_asset_id, param(:text_asset_id))
      text_asset_form.add_hidden(Text_Asset.content_id, param(:content_id_child))
      text_asset_form.add_hidden(Container.content_id_parent, param(:content_id_parent))
      text_asset_form.set_groups([:empty])

      render_view('container_form.rhtml', 
                  :text_asset => text_asset, 
                  :content_id_child => param(:content_id_child), 
                  :content_id_parent => param(:content_id_parent), 
                  :text_asset_form => text_asset_form.string, 
                  :media_asset_list => media_list,
                  :custom_forms => view_string('custom_model_choose.rhtml', 
                                               :models => Model_Register.all, 
                                               :form_asset => form_asset, 
                                               :form_options => Form_Builder_Controller.show_options_string(:form_asset => form_asset)))
    end

    def update_inline

      text_asset = Text_Asset.load(:text_asset_id => param(:text_asset_id))

      article = Article.select { |a|
       a.where(Article.content_id.in( Container.select(:content_id_parent) { |cip|
         cip.where(Container.content_id_child == text_asset.content_id)
         cip.limit(1)
       }))
       a.limit(1)
      }.first

      editor = Textarea_Field.new(:name => Text_Asset.text, :value => text_asset.text)
      editor.style_class = 'fullwidth'

    # exec_js("init_all_editors();")
      render_view(:container_inline_form, 
                  :article => article, 
                  :text_asset_id => text_asset.text_asset_id, 
                  :content_id_parent => param(:content_id_parent), 
                  :content_id_child => param(:content_id_child), 
                  :article_id => article.article_id, 
                  :content_id => text_asset.content_id, 
                  :text => text_asset.text)
      
    end

    def delete
      form = delete_form(Text_Asset)
      form.fields = [ Text_Asset.text, Text_Asset.tags, 
                      Container.content_id_parent, Container.content_id_child ]
      form.add_hidden(Container.content_id_parent => param(:content_id_parent))
      form.add_hidden(Container.content_id_child => param(:content_id_child))
      render_form(form)
    end
    
  end

end
end
end

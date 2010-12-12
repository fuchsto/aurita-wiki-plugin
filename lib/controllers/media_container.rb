
require('aurita/plugin_controller')

Aurita.import_plugin_model :wiki, :media_container
Aurita.import_plugin_model :wiki, :media_container_entry
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_module :wiki, 'gui/media_container_partial'

module Aurita
module Plugins
module Wiki

  class Media_Container_Controller < Plugin_Controller
    
    def article_partial(params={})
      article         = params[:article]
      media_container = params[:part]
      viewparams      = params[:viewparams]
      GUI::Media_Container_Partial.new(media_container)
    end

    def perform_add
      @params[:tags] = ':media_container'

      content_id_parent = param(:content_id_parent) 
      content_id_parent = param(:content_id) unless content_id_parent
      instance   = super()
      position   = param(:position)
      position ||= param(:sortpos)

      article = Article.find(1).with(Article.content_id == content_id_parent).entity
      article.add_partial(instance, 
                          :position    => position, 
                          :after_asset => param(:after_asset))

      redirect_to(article, :edit_inline_content_id => instance.content_id, 
                           :article_id             => article.article_id, 
                           :edit_inline_type       => 'MEDIA_CONTAINER')

    end

    def update_inline
      
      instance  = Media_Container.find(1).with(Media_Container.asset_id == param(:asset_id_child)).entity
      container = Container.find(1).with((Container.content_id_parent == param(:content_id_parent)) & 
                                         (Container.asset_id_child == param(:asset_id_child))).entity
      
      render_view(:container_attachments, 
                  :article          => instance.article, 
                  :container        => container, 
                  :media_container  => instance, 
                  :media_asset_list => Media_Asset_Controller.choice_list(:selected => instance.media_assets))
    end

    def perform_update
      instance = load_instance()

      Media_Container_Entry.delete { |e|
        e.where(Media_Container_Entry.media_container_id == instance.media_container_id)
      }

      param(:selected_media_assets, []).each { |media_asset_id|
        if media_asset_id.nonempty? then
          Media_Container_Entry.create(:media_container_id => instance.media_container_id, 
                                       :media_asset_id     => media_asset_id, 
                                       :position           => 0)
        end
      }
      redirect_to(:controller => 'Wiki::Article', :article_id => instance.article.article_id)
    end

  end

end
end
end


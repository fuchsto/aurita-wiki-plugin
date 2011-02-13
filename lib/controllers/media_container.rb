
require('aurita/plugin_controller')

Aurita.import_plugin_model :wiki, :media_container
Aurita.import_plugin_model :wiki, :media_container_entry
Aurita.import_plugin_model :wiki, :media_asset
Aurita.import_plugin_module :wiki, :gui, :media_container_partial
Aurita.import_plugin_module :wiki, :gui, :media_container_dump_partial

module Aurita
module Plugins
module Wiki

  class Media_Container_Controller < Plugin_Controller
    
    def article_partial(params={})
      media_container   = params[:part]
      media_container ||= load_instance()
      GUI::Media_Container_Partial.new(media_container)
    end

    def article_version_partial(params={})
      media_container   = params[:part]
      media_container ||= load_instance()
      GUI::Media_Container_Dump_Partial.new(media_container)
    end

    def add
      # undef
    end

    def update
      instance    = load_instance()
      instance  ||= Media_Container.find(1).with(Media_Container.asset_id == param(:asset_id_child)).entity
      
      render_view(:container_attachments, 
                  :article          => instance.article, 
                  :media_container  => instance, 
                  :media_asset_list => Media_Asset_Controller.choice_list(:selected => instance.media_assets))
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

#      redirect_to(article, :edit_inline_content_id => instance.content_id, 
#                           :article_id             => article.article_id, 
#                           :edit_inline_type       => 'MEDIA_CONTAINER')
      
      dom_insert(:after_element      => "article_part_asset_#{param(:after_asset)}",
                 :action             => :update, 
                 :media_container_id => instance.media_container_id, 
                 :after_asset        => param(:after_asset))

      return instance

    end
    
    def perform_update
      instance = load_instance()
      article  = instance.article()

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

      article.commit_version('U:Media_Container')
      
      redirect(:element            => "article_part_asset_#{instance.asset_id}_contextual", 
               :action             => :article_partial, 
               :media_container_id => instance.media_container_id)
      
      return instance
    end

  end

end
end
end


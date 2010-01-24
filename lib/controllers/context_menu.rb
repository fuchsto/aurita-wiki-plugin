
require('aurita/controller')
Aurita::Main.import_controller :context_menu
Aurita.import_module :context_menu_helpers

module Aurita
module Plugins
module Wiki

  class Context_Menu_Controller < Aurita::Plugin_Controller
  include Aurita::Context_Menu_Helpers

    def article()
      article_id = param(:article_id)
      article = Article.load(:article_id => article_id)

      content_id = article.content_id
      targets = { } 
      title = article.title
      title = title[0..30] << ' ...' if title.length > 33
      header(tl(:article) +': '+title)

      entry(:bookmark_article, "Bookmarking::Bookmark/perform_add/type=ARTICLE&url=article--#{article_id}&title=#{article.title}&user_id=#{Aurita.user.user_group_id}", targets)
      entry(:recommend_article, "Content_Recommendation/editor/type=ARTICLE&content_id=#{content_id}")

      if !param(:no_inline) && Aurita.user.may_edit_content?(article) then 
        switch_to_entry(:add_text_partial, "Wiki::Text_Asset/perform_add/content_id=#{content_id}") 
        switch_to_entry(:add_files_partial, "Wiki::Media_Container/perform_add/content_id=#{content_id}") 

        plugin_get(Hook.wiki.article.hierarchy.partial_type).each { |type|
          model    = type[:model]
          label    = type[:label]
          action   = type[:action]
          action ||= :add
          entry(label, "#{model.model_name}/#{action}/content_id=#{content_id}") 
        }

        if Aurita.user.may(:change_meta_data_of_foreign_articles) || Aurita.user.user_group_id == article.user_group_id then 
          entry(:edit_article, "Wiki::Article/update/article_id=#{article_id}", targets)
        end
        if Aurita.user.is_admin? || Aurita.user.user_group_id == article.user_group_id then 
          entry(:edit_article_permissions, "Content_Permissions/editor/content_id=#{content_id}", targets)
        end
        if Aurita.user.may(:delete_foreign_articles) or Aurita.user.user_group_id == article.user_group_id then 
          entry(:delete_article_versions, "Wiki::Article_Version/perform_delete_all/article_id=#{article_id}", targets) 
          entry(:delete_article, "Wiki::Article/delete/article_id=#{article_id}", targets) 
        end
      end
    end

    def media_asset()
      header(tl(:asset))
      media_asset_id = param(:media_asset_id)
      media_asset = Media_Asset.load(:media_asset_id => media_asset_id)
      content_id = media_asset.content_id

      if Aurita.user.may_edit_content?(media_asset) then
        if Aurita.user.may(:change_meta_data_of_foreign_files) || media_asset.user_group_id == Aurita.user.user_group_id then
          entry(:edit_asset, "Wiki::Media_Asset/update/media_asset_id=#{media_asset_id}")
        end
        entry(:new_asset_version, "Wiki::Media_Asset_Version/add/media_asset_id=#{media_asset_id}")
        if Aurita.user.may(:delete_foreign_files) || media_asset.user_group_id == Aurita.user.user_group_id then
          entry(:delete_asset, "Wiki::Media_Asset/delete/media_asset_id=#{media_asset_id}")
        end
        if media_asset.is_image? then
        #  load_entry(:edit_image, 'app_main_content' => "Wiki::Image_Editor/main/media_asset_id=#{media_asset_id}")
        end
      end
      entry(:bookmark_asset, "Bookmarking::Media_Asset_Bookmark/perform_add/media_asset_id=#{media_asset_id.to_s}")
      entry(:recommend_asset, "Content_Recommendation/editor/type=ASSET&content_id=#{content_id}")
      link_entry(:download_asset, "#{Aurita::Project_Configuration.remote_path}/aurita/Wiki::Media_Asset/proxy/media_asset_id=#{media_asset.media_asset_id}")
    end

    def media_asset_version
      version     = Media_Asset_Version.load(:media_asset_version_id => param(:media_asset_version_id))
      media_asset = Media_Asset.load(:media_asset_id => version.media_asset_id)
      header(tl(:version) + " #{version.version}")
      link_entry(:download_version, "#{Aurita::Project_Configuration.remote_path}/aurita/Wiki::Media_Asset/proxy/media_asset_id=#{media_asset.media_asset_id}&version=#{version.version}")
    end

    def media_asset_container
      media_asset()
      container()
    end

    def text_asset()

      asset_id_child    = param(:asset_id_child)
      content_id_parent = param(:content_id_parent)
      targets = { "article_#{param(:article_id)}" => "Wiki::Article/show/article_id=#{param(:article_id)}" }

      article = Article.load(:article_id => param(:article_id))
      if !Aurita.user.may_edit_content?(article) then 
        render_view(:message_box, :message => tl(:article_is_locked))
        return
      end
     
      header(tl(:text))
      load_entry(:edit_text, { "article_part_asset_#{asset_id_child}" => "Wiki::Text_Asset/update_inline/asset_id_child=#{asset_id_child}&content_id_parent=#{content_id_parent}&asset_id=#{asset_id_child}" })

      container()
    end

    def media_container()

      asset_id_child    = param(:asset_id_child)
      content_id_parent = param(:content_id_parent)
      targets = { "article_#{param(:article_id)}" => "Wiki::Article/show/article_id=#{param(:article_id)}" }

      article = Article.load(:article_id => param(:article_id))
      if !Aurita.user.may_edit_content?(article) then 
        render_view(:message_box, :message => tl(:article_is_locked))
        return
      end
     
      header(tl(:media_container))
      load_entry(:edit_media_container, { "article_part_asset_#{asset_id_child}" => "Wiki::Media_Container/update_inline/asset_id_child=#{asset_id_child}&content_id_parent=#{content_id_parent}&asset_id=#{asset_id_child}" })

      container()
    end
    
    def container
     
      asset_id_child    = param(:asset_id_child)
      content_id_parent = param(:content_id_parent)

      container_clicked = Container.load(:content_id_parent => content_id_parent, 
                                         :asset_id_child    => asset_id_child)

      header(tl(:container))
      if !container_clicked then 
        puts "<div style=\"padding: 3px; \">#{tl(:cannot_be_edited)}</div>"
        return
      end

      targets = { "article_#{param(:article_id)}" => "Wiki::Article/show/article_id=#{param(:article_id)}" }
 
      switch_to_entry(:add_text_partial, "Wiki::Text_Asset/perform_add/content_id=#{content_id_parent}")
      switch_to_entry(:add_files_partial, "Wiki::Media_Container/perform_add/content_id=#{content_id_parent}")
      entry(:delete_container,  "Wiki::Container/delete/asset_id_child=#{asset_id_child}&content_id_parent=#{content_id_parent}&asset_id=#{asset_id_child}", {})
      switch_to_entry(:reorder, "Wiki::Article/show_sortable/article_id=#{param(:article_id)}&reorder=1")
    end

    def media_asset_folder
      folder_id = param(:media_asset_folder_id).to_s
      if !(Aurita.user.may_edit_folder?(folder_id)) then
        puts tl(:no_permission_to_edit_folder)
        return
      end
      folder = Media_Asset_Folder.load(:media_asset_folder_id => folder_id)
      header(tl(:media_folder))
      entry(:edit_folder, 'Wiki::Media_Asset_Folder/update/media_asset_folder_id='+folder_id) unless folder.access == 'PRIVATE'
      entry(:add_subfolder, 'Wiki::Media_Asset_Folder/add/media_folder_id__parent='+folder_id)
      entry(:delete_folder, 'Wiki::Media_Asset_Folder/delete/media_asset_folder_id='+folder_id) unless folder.access == 'PRIVATE'
    end

    def media_asset_folder_box
      header(tl(:media_folder))
      entry(:add_folder, 'Wiki::Media_Asset_Folder/add/')
    end

    
  end

end
end
end


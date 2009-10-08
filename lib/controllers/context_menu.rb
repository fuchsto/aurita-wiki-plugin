
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
      if Aurita.user.may_edit_content?(article) then 
        entry(:add_container, "Wiki::Container/add/content_id=#{content_id}", targets) unless param(:no_inline)
        if Aurita.user.is_admin? or Aurita.user.user_group_id == article.user_group_id then 
          entry(:edit_article, "Wiki::Article/update/article_id=#{article_id}", targets)
          entry(:edit_article_permissions, "Content_Permissions/editor/content_id=#{content_id}", targets)
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
        entry(:edit_asset, "Wiki::Media_Asset/update/media_asset_id=#{media_asset_id}")
        entry(:new_asset_version, "Wiki::Media_Asset_Version/add/media_asset_id=#{media_asset_id}")
        if Aurita.user.is_admin? || media_asset.user_group_id == Aurita.user.user_group_id then
          entry(:delete_asset, "Wiki::Media_Asset/delete/media_asset_id=#{media_asset_id}")
        end
        if media_asset.is_image? then
          load_entry(:edit_image, 'app_main_content' => "Wiki::Image_Editor/main/media_asset_id=#{media_asset_id}")
        end
      end
      entry(:bookmark_asset, "Bookmarking::Media_Asset_Bookmark/perform_add/media_asset_id=#{media_asset_id.to_s}")
      entry(:recommend_asset, "Content_Recommendation/editor/type=ASSET&content_id=#{content_id}")
      entry(:download_asset, "#{Aurita::Project_Configuration.remote_path}assets/#{media_asset.filename}")
    end

    def media_asset_version
      version = Media_Asset_Version.load(:media_asset_version_id => param(:media_asset_version_id))
      media_asset = Media_Asset.load(:media_asset_id => version.media_asset_id)
      header(tl(:version) + " #{version.version}")
      entry(:download_version, "#{Aurita::Project_Configuration.remote_path}assets/#{media_asset.filename(version.version)}")
    end

    def media_asset_container
      media_asset()
      container()
    end

    def text_asset()
      text_asset_id = param(:text_asset_id)
      content_id    = param(:content_id)
      text_asset    = Text_Asset.load(:text_asset_id => text_asset_id)

      article = Article.load(:article_id => param(:article_id))
      if !Aurita.user.may_edit_content?(article) then 
        render_view(:message_box, :message => tl(:article_is_locked))
        return
      end
     
      targets = { 'article_' << param(:article_id) => 'Wiki::Article/show/article_id=' << param(:article_id) }
 
      header(tl(:text))
      entry(:edit_text, "Wiki::Text_Asset/update/text_asset_id=#{text_asset_id}", targets)
    end
    
    def container
      article = Article.load(:article_id => param(:article_id))
      if !Aurita.user.may_edit_content?(article) then 
        render_view(:message_box, :message => tl(:article_is_locked))
        return
      end
     
      content_id_child  = param(:content_id_child)
      content_id_parent = param(:content_id_parent)
      text_asset_id     = param(:text_asset_id)

      text_asset_clicked = Container.load(:content_id_parent => content_id_parent, 
                                          :content_id_child => content_id_child)

      header(tl(:container))
      if !text_asset_clicked then 
        puts "<div style=\"padding: 3px; \">#{tl(:cannot_be_edited)}</div>"
        return
      end

      targets = { "article_#{param(:article_id)}" => "Wiki::Article/show/article_id=#{param(:article_id)}" }
 
      load_entry(:edit_text, { "text_asset_#{text_asset_clicked.content_id_child}" => "Wiki::Container/update_inline/content_id_child=#{content_id_child}&content_id_parent=#{content_id_parent}&text_asset_id=#{text_asset_id}" })
#     entry(:edit_container, 'Wiki::Container/update/content_id_child='+content_id_child+'&content_id_parent='+content_id_parent+'&text_asset_id='+text_asset_id, targets)
      load_entry(:edit_attachments, { ("container_#{text_asset_clicked.content_id_child}_attachments") => "Wiki::Container/edit_attachments/content_id_child=#{content_id_child}&content_id_parent=#{content_id_parent}&text_asset_id=#{text_asset_id}" } )
      entry(:add_container,     "Wiki::Container/add/content_id=#{content_id_parent}", targets)
      entry(:delete_container,  "Wiki::Container/delete/content_id_child=#{content_id_child}&content_id_parent=#{content_id_parent}&text_asset_id=#{text_asset_id}", {})
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


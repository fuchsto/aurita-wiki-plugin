
require('aurita/plugin_controller')
begin
	Aurita.import_plugin_module :syntax, :string_decorator
rescue LoadError => ignore
end

Aurita.import_plugin_module :wiki, :gui, :article_select_field
Aurita.import_plugin_module :wiki, :gui, :media_asset_selection_field
Aurita.import_plugin_module :wiki, :gui, :text_asset_partial
Aurita.import_plugin_module :wiki, :gui, :text_asset_dump_partial
Aurita.import_plugin_module :wiki, :gui, :text_asset_editor

module Aurita
module Plugins
module Wiki

  # TODO: This should be a filter chain built by plugin hooks
  #
  class Text_Asset_Parser
    def self.parse(text)
      return text

      text.gsub!(/\[code ([^\]]+)\]\s*<br\/>/m,'[code \1]')
      text.gsub!("\n[/code]",'[/code]')
      text.gsub(/\[code ([^\]]+)\](.+?)\[\/code\]/) { |code| 
      	string = code.gsub(/\[code ([^\]]+)\](.+)\[\/code\]/, '\2')
      	lang   = code.gsub(/\[code ([^\]]+)\](.+)\[\/code\]/, '\1')
        string.gsub!('&amp;','&')
        string.gsub!('&nbsp;',' ')
        string.gsub!('&lt;',"<")
        string.gsub!('&gt;',">")
        string.gsub!('<br />',"\n")
        string = Syntax::String_Decorator.highlight_string(string, lang)
        string.gsub!('<span class="lnr"',"<br /><span class=\"lnr\"")
        
        string.gsub!(/^(\s+)<br \/>/,'')
        string.gsub!('`',"'")
        string
      }
    end
  end

  class Text_Asset_Controller < Plugin_Controller

    def form_groups
      [
        Text_Asset.text
      ]
    end

    def article_partial(params={})
      text_asset   = params[:part]
      text_asset ||= load_instance
      GUI::Text_Asset_Partial.new(text_asset)
    end

    def article_version_partial(params={})
      article    = params[:article]
      text_asset = params[:part]
      viewparams = params[:viewparams]
      GUI::Text_Asset_Dump_Partial.new(text_asset)
    end

    # Partial without Context_Element decoration
    def update
      text_asset   = load_instance()
      text_asset ||= Text_Asset.find(1).with(Text_Asset.asset_id == param(:asset_id)).entity
      article      = text_asset.article

      return unless Aurita.user.may_edit_content?(article)
      
      GUI::Text_Asset_Editor.new(:text_asset  => text_asset, 
                                 :article     => article, 
                                 :after_asset => param(:after_asset))

    end

    def add
      # undef
    end

    # Partial as Context_Element (returns GUI::Article_Partial)
    def partial
      text_asset   = load_instance()
      text_asset ||= Text_Asset.find(1).with(Text_Asset.asset_id == param(:asset_id)).entity
      article      = text_asset.article

      return unless Aurita.user.may_edit_content?(article)
      
      partial = GUI::Text_Asset_Editor.new(:text_asset  => text_asset, 
                                           :article     => article, 
                                           :after_asset => param(:after_asset))
      
      GUI::Article_Partial.new(:article => article, 
                               :partial => partial, 
                               :entity  => text_asset)
    end

    def perform_add()

      text = param(:text, tl(:text_asset_blank_text))
      if Wiki::Plugin.surpress_article_tag_links then
        @params[:display_text] = text
      else
        @params[:display_text] = Tagging.link_text_tags(Text_Asset_Parser.parse(param(:text).to_s.dup))
      end
      @params[:tags] = :text

      content_id_parent = param(:content_id_parent) 
      content_id_parent = param(:content_id) unless content_id_parent
      instance   = super()
      
      article = Article.find(1).with(Article.content_id == content_id_parent).entity

      position   = param(:position)
      position ||= param(:sortpos)
      article.add_partial(instance, 
                          :position    => position, 
                          :after_asset => param(:after_asset))
      
      dom_insert(:after_element => "article_part_asset_#{param(:after_asset)}",
                 :action        => :partial, 
                 :text_asset_id => instance.text_asset_id, 
                 :after_asset   => param(:after_asset))

      return instance
    end

    def perform_delete()
=begin
# See Container.perform_delete

      content_id   = param(:content_id)
      content_id ||= Container.value_of(Container.content_id_parent).where(
                       Container.content_id_child == param(:content_id)
                     ).to_i
      article = load_instance().article
      # Load text asset in container
      asset = Asset.find(1).with(Asset.asset_id == container.asset_id_child).polymorphic.entity

      exec_js("Element.hide('article_part_asset_#{asset_asset_id}'); ")

      result = super()
      container.delete
      article.commit_version('D:Text_Asset')
      result
=end
    end

    def perform_update
      param[:text] = param(:text).to_s.gsub("'",'&apos;')
      if Wiki::Plugin.surpress_article_tag_links then
        @params[:display_text] = param(:text)
      else
        @params[:display_text] = Tagging.link_text_tags(Text_Asset_Parser.parse(param(:text).to_s.dup))
      end
      result   = super()
      instance = load_instance()
      article  = load_instance().article
      
      article.commit_version('U:Text_Asset')
  
      redirect(:element       => "article_part_asset_#{instance.asset_id}_contextual", 
               :action        => :article_partial, 
               :text_asset_id => instance.text_asset_id)

      return result
    end

    def list
    end

    def editor_link_dialog()
      use_decorator(:async)

      form = GUI::Form.new(:id => :editor_link_form) 
      form.onsubmit = "Aurita.Wiki.insert_link('article_link_id', 'website_link'); return false;"
=begin
      form.add(GUI::Select_Field.new(:options => { :_blank => tl(:open_in_new_window), 
                                                   :_self  => tl(:open_in_same_window) }, 
                                     :value   => :_self, 
                                     :label   => tl(:link_target), 
                                     :name    => :target))
=end
      form.add(GUI::Article_Select_Field.new(:name  => :article, 
                                             :key   => :article_id, 
                                             :label => tl(:link_to_article), 
                                             :id    => :article_link))
      
      form.add(GUI::Media_Asset_Selection_Field.new(:name       => :media_asset, 
                                                    :key        => :media_asset_id, 
                                                    :label      => tl(:link_to_media_asset), 
                                                    :row_action => 'Wiki::Media_Asset/editor_list_link_choice', 
                                                    :id         => :media_asset_link))
=begin
      form.add(GUI::Media_Asset_Selection_Field.new(:name       => :media_asset_download, 
                                                    :key        => :media_asset_id, 
                                                    :label      => tl(:link_to_media_asset_download), 
                                                    :row_action => 'Wiki::Media_Asset/editor_list_download_link_choice', 
                                                    :id         => :media_asset_download_link))
=end
      plugin_get(Hook.wiki.text_asset.link_editor).each { |field|
        form.add(field)
      }
      
      form.add(GUI::Text_Field.new(:name  => :url, 
                                   :label => tl(:link_to_website), 
                                   :id    => :website_link))

      decorate_form(form, 
                    :onclick_ok     => "$('editor_link_form').onsubmit(); $('message_box').hide();", 
                    :onclick_cancel => "$('message_box').hide();")
    end

  end # class
  
end # module
end # module
end # module


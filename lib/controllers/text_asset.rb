
require('aurita/plugin_controller')
Aurita.import_plugin_module :syntax, :string_decorator
Aurita.import_plugin_module :wiki, 'gui/article_selection_field'

module Aurita
module Plugins
module Wiki

  # TODO: This should be a filter chain built by plugin hooks
  #
  class Text_Asset_Parser
    def self.parse(text)
      text.gsub!(/\[code ([^\]]+)\]\s*<br\/>/m,'[code \1]')
      text.gsub!("\n[/code]",'[/code]')
      text.gsub(/\[code ([^\]]+)\](.+?)\[\/code\]/) { |code| 
      	string = code.gsub(/\[code ([^\]]+)\](.+)\[\/code\]/, '\2')
      	lang = code.gsub(/\[code ([^\]]+)\](.+)\[\/code\]/, '\1')
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
      article    = params[:article]
      text_asset = params[:part]
      viewparams = params[:viewparams]
      HTML.div.article_partial(:id => "text_asset_#{text_asset.text_asset_id}") { text_asset.display_text }
    end

    def update_inline
      text_asset = Text_Asset.find(1).with(Text_Asset.asset_id == param(:asset_id)).entity
      article    = text_asset.article
      editor     = Textarea_Field.new(:name => Text_Asset.text, :value => text_asset.text)
      editor.style_class = 'fullwidth'

      render_view(:container_inline_form, 
                  :article           => article, 
                  :text_asset_id     => text_asset.text_asset_id, 
                  :content_id_parent => param(:content_id_parent), 
                  :asset_id_child    => param(:asset_id_child), 
                  :article_id        => article.article_id, 
                  :content_id        => text_asset.content_id, 
                  :text              => text_asset.text)
    end

    def perform_add()

      text                   = param(:text, tl(:text_asset_blank_text))
      @params[:display_text] = Tagging.link_text_tags(Text_Asset_Parser.parse(param(:text).to_s.dup))
      @params[:tags]         = 'text'

      content_id_parent = param(:content_id_parent) 
      content_id_parent = param(:content_id) unless content_id_parent
      instance = super()

      if(param(:sortpos).to_s != '') then
        max_offset = Container.value_of.max(:sortpos).where(Container.content_id_parent == param(:content_id))
        max_offset = 0 if max_offset.nil? 
        sortpos = max_offset.to_i+1
      else
        sortpos = param(:sortpos).to_i
      end

      container = Container.create(
                    :content_id_parent => content_id_parent, 
                    :asset_id_child    => instance.asset_id, 
                    :sortpos           => sortpos
                  )

      article = Article.find(1).with(Article.content_id == content_id_parent).entity
      article.commit_version('ADD:TEXT_ASSET')

      redirect_to(article, :edit_inline_content_id => instance.content_id, 
                           :article_id             => article.article_id, 
                           :edit_inline_type       => 'TEXT_ASSET')

      return instance
    end

    def perform_delete()

      content_id = Container.value_of(Container.content_id_parent).where(
                      Container.content_id_child == param(:content_id)
                   ).to_i
      Content.touch(content_id, 'DELETE:TEXT')
      exec_js("Element.hide('container_#{param(:content_id)}'); ")

      super()
    end

    def perform_update
      param[:text]         = param(:text).to_s.gsub("'",'&apos;')
      param[:display_text] = Tagging.link_text_tags(Text_Asset_Parser.parse(param(:text).to_s.dup))
      result  = super()
      article = load_instance().article
      article.touch('UPDATE:TEXT')
      redirect_to(article)
      return result
    end

    def list
    end

    def editor_link_dialog()
      use_decorator(:async)

      form = GUI::Form.new(:id => :editor_link_form) 
      form.onsubmit = "Aurita.Wiki.insert_link_to_article($('article_link_id').value); return false;"

      form.add(GUI::Article_Selection_Field.new(:name  => :article, 
                                                :key   => :article_id, 
                                                :label => tl(:link_to_article), 
                                                :id    => :article_link))
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


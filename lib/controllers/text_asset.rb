
require('aurita/plugin_controller')
Aurita.import_plugin_module :syntax, :string_decorator

module Aurita
module Plugins
module Wiki

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

    def article_hierarchy_part(params={})
      instance = params[:part]

    end

    def perform_add()

      @params[:display_text] = Text_Asset_Parser.parse(Tagging.link_text_tags(param(:text).to_s.dup))
      @params[:tags] = 'text'
      content_id_parent = param(:content_id_parent) if param(:content_id_parent)
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
                    :content_id_child => instance.content_id, 
                    :sortpos => sortpos
                  )

      Content.touch(container.content_id_parent, 'ADD:TEXT')
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
      content_id = Container.value_of(Container.content_id_parent).where(
                      Container.content_id_child == param(:content_id)
                   ).to_i
      result = super()
      Article.touch(content_id, 'UPDATE:TEXT')
      redirect_to(:controller => 'Wiki::Article', :action => :show, :article_id => load_instance().article.article_id)
      return result
    end

    def after_add(params)
      puts '<div class="notification">Text added</div>'
    end
    def after_update(params)
      puts '<div class="notification">Text updated</div>'
    end
    def after_delete(params)
      puts '<div class="notification">Text deleted</div>'
    end

    def list
    end

    def editor_link_dialog()
      render_view(:editor_link_dialog)
    end

  end # class
  
end # module
end # module
end # module


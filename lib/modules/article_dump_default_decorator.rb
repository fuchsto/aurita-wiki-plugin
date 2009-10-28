
require('aurita/controller')
require('enumerator')

Aurita.import_plugin_module :wiki, :article_hierarchy_default_decorator

module Aurita
module Plugins
module Wiki

  class Article_Dump_Default_Decorator < Article_Hierarchy_Default_Decorator
  include Aurita::GUI::Helpers
  extend Aurita::GUI::Helpers
  include Aurita::GUI

    attr_accessor :hierarchy
    attr_reader :viewparams

    
    def initialize(version_entry, templates={})
      @version_entry = version_entry
      @templates = { :article           => :article_decorator, 
                     :form_view_rows    => :form_view_vertical, 
                     :form_view_cols    => :form_view, 
                     :form_element_rows => :form_element_listed, 
                     :form_element_cols => :form_element_horizontal }
      @templates.update(templates)
      @hierarchy = eval(version_entry.dump)
    end

    protected

    # Expands dump to full hierarchy. 
    def decorate_article
      article_content_id     = @hierarchy.keys.first
      article_set            = @hierarchy[article_content_id]
      article                = Article.find(1).with(Article.content_id == article_content_id).entity
      article_set[:instance] = article
      article_set[:text_assets].map { |ta|
        text   = ta[:text_asset].dup
        text ||= ta[:text].dup
        ta[:text_asset] = Text_Asset.create_shallow(:text          => text, 
                                                    :display_text  => text, 
                                                    :tags          => 'text', 
                                                    :content_id    => 0, 
                                                    :text_asset_id => 0)
        ta[:media_assets].map! { |ma| 
          ma = Media_Asset.load(:media_asset_id => ma)
        }
        
      # TODO: Use plugin hooks here: 
      #  ta[:todo_asset] = Todo_Asset.load(:todo_asset_id => ta[:todo_asset]) if ta[:todo_asset]
      #  ta[:form_asset] = Form_Asset.load(:form_asset_id => ta[:form_asset]) if ta[:form_asset]
        
        parts = Aurita::Plugin_Register.get(Hook.wiki.article.article_part, 
                                            :article    => article, 
                                            :text_asset => ta[:text_asset_id])

        parts.each { |part|
          ta[part.part_type] = part.part_entity
        }
      }
      @hierarchy[article_content_id] = article_set

      author_user             = User_Group.load(:user_group_id => article.user_group_id)
      version_author_user     = User_Group.load(:user_group_id => @version_entry.user_group_id)
      latest_version          = article.latest_version
      if latest_version then
        last_change_user = User_Group.load(:user_group_id => article.latest_version.user_group_id) 
      else
        last_change_user = author_user
      end

      article_string = ''
      text_assets = article_set[:text_assets]
      text_assets.each { |ta|
        article_string << decorate_container(ta, article)
      }
      @string = view_string(@templates[:article], 
                            :article             => article, 
                            :latest_version      => article.latest_version_number, 
                            :version_dump        => article_set, 
                            :version_entry       => @version_entry, 
                            :article_content     => article_string, 
                            :active_version      => @version_entry.version, 
                            :version_author_user => version_author_user, 
                            :last_change_user    => last_change_user, 
                            :author_user         => author_user, 
                            :content_tags        => article_set[:article][:tags], 
                            :entry_counter       => 0)

    end

  end

end
end
end


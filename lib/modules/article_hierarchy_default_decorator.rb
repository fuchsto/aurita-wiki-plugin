
require('aurita/plugin_controller')
require('enumerator')

Aurita.import :base, :plugin_methods
Aurita.import_plugin_module :wiki, :gui, :article_partial


module Aurita
module Plugins
module Wiki

  class Article_Hierarchy_Default_Decorator < Plugin_Controller
  include Aurita::Plugin_Methods
  include Aurita::GUI::Helpers
  extend Aurita::GUI::Helpers
  include Aurita::GUI

    attr_accessor :hierarchy, :viewparams, :templates
    
    def initialize(article_or_hierarchy, templates={})
      if article_or_hierarchy.kind_of?(Article) then
        @hierarchy ||= false
        @article   ||= article_or_hierarchy
      else
        @hierarchy ||= article_or_hierarchy
        @article   ||= false
      end
      @article  ||= @hierarchy[:instance]
      @string     = ''
      @viewparams = {}
      if(!@templates) then
        @templates  = { :article           => :article_decorator, 
                        :article_public    => :article_public_decorator, 
                        :form_view_rows    => :form_view_vertical, 
                        :form_view_cols    => :form_view, 
                        :form_element_rows => :form_element_listed, 
                        :form_element_cols => :form_element_horizontal }
        @templates.update(templates)
      end
      @partial_index = 0
    end

    def parts()
      return @parts if @parts
      @parts = @hierarchy[:parts]
      @parts
    end

    def parts_decorated()
      return @parts_decorated if @parts_decorated
      @partial_index   = 0
      @parts_decorated = parts().map { |p|
        decorate_part(p, @article) if p
      }
      @parts_decorated
    end

    def string
      decorate_article()
      return @string
    end

    def viewparams=(params)
      params.to_s.split('--').each_slice(2) { |k,v| @viewparams[k.to_s] = v.to_s }
    end

    protected

    def decorate_article(article=nil)
      article        ||= @article
      article_comments = Content_Comment_Controller.list_string(article.content_id) 
      article_tags     = view_string(:editable_tag_list, :content => article)
      article_version  = Article_Version.value_of.max(:version).with(Article_Version.article_id == article.article_id).to_i
      
      author_user      = User_Profile.load(:user_group_id => article.user_group_id) 
      latest_version   = article.latest_version
      if latest_version then
        last_change_user = User_Profile.load(:user_group_id => article.latest_version.user_group_id) 
      else
        last_change_user = author_user
      end
      
      article_string = ''
      parts_decorated().each { |part|
        article_string << part.to_s 
      }
      
      template = @templates[:article]
      template = @templates[:article_public] if @viewparams['public'] == 'false' 
      @string = view_string(template, 
                            :article          => article, 
                            :article_content  => article_string, 
                            :article_version  => article_version, 
                            :last_change_user => last_change_user, 
                            :author_user      => author_user, 
                            :content_tags     => article_tags, 
                            :content_comments => article_comments, 
                            :entry_counter    => 0)
    end

    def decorate_part(part, article=nil)
      article        ||= @article
      part_entity      = part[:instance]
      
      @partial_index += 1
      
      partial = Plugin_Register.get(Hook.wiki.article.hierarchy.partial, 
                                    self, 
                                    :article    => article, 
                                    :viewparams => @viewparams, 
                                    :part       => part_entity).first
      
      GUI::Article_Partial.new(:partial        => partial, 
                               :article        => article, 
                               :partial_entity => part_entity)
    end

  end

end
end
end


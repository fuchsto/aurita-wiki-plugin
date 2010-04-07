
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
      @hierarchy     = eval(version_entry.dump)
      article_meta   = @hierarchy[:meta]
      @article       = Article.get(article_meta[:article_id])
      super(@hierarchy)
      
      STDERR.puts '---------- HIER ----------'
      STDERR.puts @hierarchy.inspect
      STDERR.puts '---------- END -----------'
    end

    def decorate_part(part, article=nil)
      part.inspect
    end

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
                            :version_entry    => @version_entry, 
                            :article          => article, 
                            :article_content  => article_string, 
                            :article_version  => article_version, 
                            :last_change_user => last_change_user, 
                            :author_user      => author_user, 
                            :content_tags     => article_tags, 
                            :content_comments => article_comments, 
                            :entry_counter    => 0)
    end

  end

end
end
end



require('aurita/plugin_controller')
Aurita.import_plugin_model :wiki, :article_version

module Aurita
module Plugins
module Wiki

  class Article_Version_Controller < Plugin_Controller

    guard(:CUD) { |c| false }

    def list
      article  = Article.get(param(:article_id))
      versions = Article_Version.all_with(:article_id => article.article_id).order_by(:version, :asc).entities
      last_version = versions.last.version
      table    = GUI::Table.new
      table.add_css_class(:list)
      table.headers = [ tl(:from), tl(:to), tl(:version), tl(:date), tl(:user) ]
      versions.each { |v|
        box_from = Radio_Field.new(:name => :compare_from, :option_values => v.version) if v.version != last_version
        box_to   = Radio_Field.new(:name => :compare_to,   :option_values => v.version) if v.version != 0
        user     = link_to(v.user) { v.user.user_group_name }
        table << [ box_from, box_to, v.version, datetime(v.timestamp_created), user ] 
      }

      Page.new(:header => tl(:compare_article_versions)) { 
        table
      }
    end

    def show
      
    end

  end

end
end
end


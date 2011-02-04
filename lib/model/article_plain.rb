
require('aurita/model')
Aurita::Main.import_model :content
Aurita.import_plugin_model :wiki, :article
Aurita.import_plugin_model :wiki, :text_asset

module Aurita
module Plugins
module Wiki
  
  class Article_Plain < Aurita::Model

    table :article_plain, :public
    primary_key :article_plain_id, :article_plain_id_seq

  end # class

  class Article < Content
    
    def reindex_content
      content = ''
      text_assets.each { |ta|
        content << ta.text.to_plaintext
      }
      article_plain   = Article_Plain.find(1).with(:article_id => article_id).entity
      article_plain ||= Article_Plain.create(:article_id => article_id)
      article_plain[:content] = content
      article_plain.commit
    end

    def self.reindex_all_content
      Article.find(:all).each { |a|
        a.reindex_content
      }
    end

  end

end # module
end # module
end # module

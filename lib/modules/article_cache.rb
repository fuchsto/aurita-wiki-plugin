
require 'aurita'

module Aurita
module Plugins
module Wiki

  class Article_Cache 

    def self.cachefile_for(article, viewparams)
      Aurita.project_path :cache, "article_#{article.article_id}__#{viewparams}.html"
    end
    def self.cachefiles_for(article)
      Aurita.project_path :cache, "article_#{article.article_id}__*"
    end

    def self.exists_for(article, viewparams='')
      begin
        cachefile = cachefile_for(article, viewparams)
        return (File.exists?(cachefile) and
                (DateTime.strptime(article.changed.gsub(' ','T')) <= File.ctime(cachefile).to_datetime))
      rescue ::Exception => excep
        return false
      end
    end

    def self.create_for(article, viewparams, &block)
      string = yield
      File.open(cachefile_for(article, viewparams), 'w') { |f|
        f << string.gsub("\n",'')
      }
    end

    def self.delete_for(article)
      File.delete(cachfiles_for(article))
    end

    def self.read(article, viewparams)
      result = ''
      File.readlines(cachefile_for(article, viewparams)).each { |l|
        result << l
      }
      return result
    end
    
  end
  
end
end
end


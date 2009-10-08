
require('aurita')
require('erb')
Aurita.import_plugin_module :wiki, :text_asset_decorator

module Aurita
module Plugins
module Wiki

  class Article_Decorator < Plugin_Controller

    attr_accessor :template

  private
    @article = false
    @text_assets = false

  public
  
    def initialize(article) 
      @article = article
      @text_assets = article.subs[:text_assets]
      @template = :article_decorator 
    end

    def with_template(template)
      @template = template
      return self
    end

    def string
      result = ''
      @text_assets.each { |text_asset| 
        result << Text_Asset_Decorator.new(text_asset).with_template(:text_asset_decorator).string
      }
      view_string(@template, 
                  :article => @article)
      return result
    end

    def print
      puts string
    end
    
  end

end
end
end


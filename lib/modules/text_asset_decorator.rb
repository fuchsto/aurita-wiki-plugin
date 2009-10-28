
require('aurita/plugin_controller')
require('erb')

module Aurita
module Plugins
module Wiki

  class Text_Asset_Decorator < Plugin_Controller

    attr_accessor :template
    
  private
    @text_asset = false
    @media_assets = false
    @form_assets = false

  public
    
    def initialize(text_asset)
      @text_asset = text_asset
      @media_assets = text_asset.subs[:media_assets]
      @form_asset = text_asset.subs[:form_asset]
      @todo_assets = text_asset.subs[:todo_assets]
      @template = :text_asset_decorator
    end

    def with_template(template)
      @template = template
      return self
    end

    def string
      images = []
      files  = []
      movies = []
      @media_assets.each { |ma|
        if ma.mime.include?('application/') then
          if ma.mime.include?('application/x-flv') then
            movies << ma
          else
            files << ma
          end
        elsif ma.mime.include?('image/') then
          images << ma
        end
      }
      view_string(@template, 
                 :text_asset => @text_asset, 
                 :image_assets => Image_Decorator.new(@image_assets).string,
                 :file_assets  => File_Decorator.new(@file_assets).string,
                 :movie_assets => Movie_Decorator.new(@movie_assets),
                 :todo_assets => Todo_Decorator.new(@todo_assets),
                 :form_asset => @form_asset)
    end
    
    def print
      puts string
    end

  end

end
end
end



require('aurita/controller')
Aurita.import_plugin_module :wiki, :article_hierarchy_default_decorator
Aurita.import_plugin_model :form_generator, :model_register

module Aurita
module Plugins
module Wiki

  class Article_Hierarchy_Sortable_Decorator < Article_Hierarchy_Default_Decorator 
  include Aurita::GUI::Helpers
  extend Aurita::GUI::Helpers
  include Aurita::GUI

    attr_accessor :hierarchy
    attr_reader :viewparams
    
    def initialize(hierarchy, templates={})
      super(hierarchy, templates.update(:article => :article_sortable_decorator))
    end
    
    def decorate_container(text_asset, article)
      ta = text_asset[:text_asset]
      container_params = { :content_id_parent => article.content_id, 
                           :content_id_child => ta.content_id, 
                           :text_asset_id => ta.text_asset_id, 
                           :article_id => article.article_id}
      tce = "<div id=\"text_asset_#{ta.content_id}\">#{ta.display_text}</div>"
      asset = { :instance => ta, :string => tce, :container_params => container_params }

      container_images = []
      container_movies = []
      container_files = [] 
      if text_asset[:media_assets].length > 0 then
        text_asset[:media_assets].each { |ma|
          case ma.doctype
          when :image then
            container_images << ma
          when :movie then
            container_movies << ma
          else
            container_files << ma
          end
        }
      end
      
      images = decorate_images(container_images, container_params) if container_images
      files  = decorate_files(container_files, container_params) if container_files 
      movies = decorate_movies(container_movies, container_params) if container_movies 
      form   = decorate_form(text_asset[:form], ta, article, container_params, []) if text_asset[:form]
      todo   = decorate_todo(text_asset[:todo], container_params) if text_asset[:todo]

      view_string(:article_container_sortable_decorator, 
                  :article => article, 
                  :text_asset => ta, 
                  :text => tce, 
                  :images => images, 
                  :files => files, 
                  :form => form, 
                  :todo => todo, 
                  :movies => movies)
    end

    def decorate_images(images, container_params)
      media_assets = []
      return '' unless images.first
      images.each { |image| 
        media_asset_id = image.media_asset_id
        mce = "<img class=\"article_image\" src=\"/aurita/assets/medium/asset_#{media_asset_id}.jpg\" />"
        media_assets << { :instance => image, :string => mce }
      }
      view_string(:article_image_decorator, :media_assets => media_assets)
    end

    def decorate_files(files, container_params)
      return '' unless files.first
      view_string(:article_files_decorator, :files => files, :container_params => container_params)
    end

    def decorate_movies(movies, container_params)
      return '' unless movies.first
      view_string(:article_movies_decorator, :movies => movies, :container_params => container_params)
    end

    def decorate_form(fa, text_asset, article, container_params, viewparams)
      tl(:form_container) + ': ' << fa.custom_model_name.gsub('Custom_','').gsub('_',' ')
    end

    def decorate_todo(todo, container_params)
      return '' unless todo
      tl(:todo_container) + ': ' << todo.name
    end
    
  end

end
end
end


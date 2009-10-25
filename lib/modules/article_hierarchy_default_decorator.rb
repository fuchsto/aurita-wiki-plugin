
require('aurita/controller')
require('enumerator')

Aurita.import_plugin_controller :todo, :todo_container_asset

module Aurita
module Plugins
module Wiki

  class Article_Hierarchy_Default_Decorator < Plugin_Controller
  include Aurita::GUI::Helpers
  extend Aurita::GUI::Helpers
  include Aurita::GUI

    attr_accessor :hierarchy, :viewparams, :templates
    
    def initialize(hierarchy, templates={})
      @hierarchy  = hierarchy
      @article    = false
      @string     = ''
      @viewparams = {}
      @templates  = { :article           => :article_decorator, 
                      :article_public    => :article_public_decorator, 
                      :form_view_rows    => :form_view_vertical, 
                      :form_view_cols    => :form_view, 
                      :form_element_rows => :form_element_listed, 
                      :form_element_cols => :form_element_horizontal }
      @templates.update(templates)
    end

    def string
      decorate_article()
      return @string
    end

    def viewparams=(params)
      params.to_s.split('--').each_slice(2) { |k,v| @viewparams[k.to_s] = v.to_s }
    end

    protected

    def decorate_article
      article     = @hierarchy[:instance]
      @article    = article
      parts       = @hierarchy[:parts]
      
      article_comments = Content_Comment_Controller.list_string(article.content_id) 
      article_tags     = view_string(:editable_tag_list, :content => article)
      article_version  = Article_Version.value_of.max(:version).with(Article_Version.article_id == article.article_id).to_i
      
      author_user      = User_Group.load(:user_group_id => article.user_group_id) 
      latest_version   = article.latest_version
      if latest_version then
        last_change_user = User_Group.load(:user_group_id => article.latest_version.user_group_id) 
      else
        last_change_user = author_user
      end
      
      article_string = ''
      parts.each { |part|
        article_string << decorate_part(part, article).to_s if part
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

    def decorate_part(part, article)
      part_entity      = part[:instance]
      container_params = { :content_id_parent => article.content_id, 
                           :content_id_child  => part_entity.content_id, 
                           :asset_id          => part_entity.asset_id, 
                           :article_id        => article.article_id}

      tce = Context_Menu_Element.new(HTML.div(:class => :article_text) { 
                                       Plugin_Register.get(Hook.wiki.article.hierarchy.partial, 
                                                           :article => article, 
                                                           :part    => part_entity) 
                                     }, 
                                     :type         => 'Wiki::Container', 
                                     :id           => "article_part_asset_#{part_entity.content_id}", 
                                     :params       => container_params)

      return tce
    end

    def decorate_images(images, container_params)
      media_assets = []
      return '' unless images.first
      images.each { |image| 
        media_asset_id = image.media_asset_id

        mce = Context_Menu_Element.new(HTML.a(:onclick => link_to(image)) { 
                                         HTML.img.article_image(:src => "/aurita/assets/medium/asset_#{media_asset_id}.jpg")
                                       }, 
                                       :params       => container_params.update(:media_asset_id => media_asset_id), 
                                       :highlight_id => "container_#{container_params[:content_id_child]}", 
                                       :type         => 'Wiki::Media_Asset_Container', 
                                       :entity => image)
        
        media_assets << { :instance => image, :string => mce.string }
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
    def decorate_todo(todo, container_params)
      return '' unless todo
      table_view = Aurita::Plugins::Todo::Todo_Container_Asset_Controller.container_string(:todo_asset => todo, :article => @article, :container_params => container_params)
      view_string(:article_todo_decorator, :todo_asset => todo, :container_params => container_params, :table_view => table_view)
    end

    def decorate_form(fa, text_asset, article, container_params)
      return '' unless fa
      Aurita::Project.import_model fa.custom_model_name.downcase
      model_register = Form_Generator::Model_Register.find(1).with(Form_Generator::Model_Register.name == fa.custom_model_name).entity

      model_klass = Aurita::Main.const_get(fa.custom_model_name)
      Aurita::Project.import_controller(fa.custom_model_name.downcase)
      model_controller = Aurita::Main.const_get(fa.custom_model_name+'_Controller')

      table_view = @viewparams[fa.custom_model_name]
      if(table_view) then 
        form_template = @templates[('form_view_' << table_view).intern]
        form_element_template = @templates[('form_element_' << table_view).intern]
      else 
        form_template = @templates[:form_view_rows]
        form_element_template = @templates[:form_element_rows]
      end
      
      form_asset_entries = []
      model_klass.all.ordered_by(fa.order_by, :asc).each { |entity|
        form = model_controller.instance_form(:instance => entity)
        form.readonly! 
        form_asset_entries << { :string => form.string , :entity => entity }
      }

      view_string(form_template, 
                  :entries          => form_asset_entries, 
                  :article_id       => article.article_id, 
                  :list_counter     => 1, 
                  :reorder_mode     => false,  
                  :text_asset       => text_asset, 
                  :article          => article, 
                  :model_register   => model_register, 
                  :form_asset       => fa, 
                  :model_klass      => model_klass, 
                  :model_controller => model_controller)
    end
    
  end

end
end
end


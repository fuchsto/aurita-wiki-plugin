
require('aurita/plugin_controller')
begin
require('hpricot')
require('prawn')
require('prawn/format')
require 'htmlentities'

module Prawn
  module Format
    module Instructions
      class Text < Base
        def initialize(state, text, options={})
          super(state)
          @text = text
          @break = options.key?(:break) ? options[:break] : text.index(/[-\xE2\x80\x94\s]/)
          @discardable = options.key?(:discardable) ? options[:discardable] : text.index(/\s/)
          @text = state.font.normalize_encoding(@text) if options.fetch(:normalize, true)
        end
      end
    end
  end
end

rescue LoadError => le
end
require('enumerator')

module Aurita
module Plugins
module Wiki

  class Article_Hierarchy_PDF_Decorator < Plugin_Controller
  include Aurita::GUI::Helpers
  include Aurita::GUI::I18N_Helpers
  include Aurita::GUI::Datetime_Helpers
  extend Aurita::GUI::Helpers
  include Aurita::GUI

    attr_accessor :hierarchy, :viewparams, :templates, :style

    def initialize(hierarchy, templates={})
      @hierarchy = hierarchy
      @string = ''
      @viewparams = {}
      @templates  = {} # none required
      @style = { 
        :header_color => '#3287D7', 
        :font_size    => 10, 
        :text_color   => '#000000'
      }
    end

    def pdf
      decorate_article()
      return @pdf
    end
    alias run pdf

    def viewparams=(params)
      params.to_s.split('--').each_slice(2) { |k,v| @viewparams[k.to_s] = v.to_s }
    end

  protected

    def decorate_article
      article_set = @hierarchy.values.first
      article = article_set[:instance]
      text_assets = article_set[:text_assets]
      
      article_version = Article_Version.value_of.max(:version).with(Article_Version.article_id == article.article_id).to_i
      
      author_user = User_Group.load(:user_group_id => article.user_group_id) 
      latest_version = article.latest_version
      if latest_version then
        last_change_user = User_Group.load(:user_group_id => article.latest_version.user_group_id) 
      else
        last_change_user = author_user
      end
      
      Prawn::Document.generate("/tmp/article_#{article.article_id}.pdf", 
                               :page_size    => 'A4', 
                               :left_margin  => 70, 
                               :right_margin => 70) do |pdf|
        pdf.bounding_box([340,770], :height => 50) { 
          pdf.image(Aurita.project.base_path + 'public/images/pdf_banner.png', :height => 50)
        }

        pdf.move_down(20)
        pdf.fill_color(@style[:header_color].sub('#',''))
        pdf.text(recode(article.title), :size => 25)
        pdf.fill_color(@style[:text_color].sub('#',''))

        pdf.move_down(3)
        pdf.text(recode(tl(:pdf_created_at) + ' ' << datetime(DateTime.now)), :size => 8)
        pdf.move_down(10)
        text_assets.each { |ta|
          decorate_container(ta, article, pdf)
        }
      end
      
    end

    def decorate_container(text_asset, article, pdf)
      ta = text_asset[:text_asset]

      container_images = []
      container_movies = []
      container_files  = [] 
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
  
      decorate_text(ta.text, pdf)
      decorate_images(article, container_images, pdf) if container_images
    # decorate_files(container_files, container_params, pdf) if container_files 
    # decorate_form(text_asset[:form], ta, article, container_params, pdf) if text_asset[:form]
    # decorate_todo(text_asset[:todo], container_params, pdf) if text_asset[:todo]
    end

    def decorate_text(text, pdf)
      text.gsub!('<p>','<br />')
      text.gsub!('</p>','<br />')
      text.gsub!(/<h(\d)>/,'<br /><h\1>')
      text.gsub!(/<\/\s?h(\d)>/,'</h\1><br />')
      text.gsub!('</ul>',"</ul><br /><br />")
      text.gsub!('</ol>',"</ol><br /><br />")
      coder = HTMLEntities.new
      text = coder.decode(text)
      text.gsub!('<li>',"<br /><li>")
      pdf.text(text, :size => @style[:font_size], 
                     :tags => { :ol => { :width => '2em' }, 
                                :ul => { :width => '2em' }, 
                                :li => { :width => '2em' }, 
                                :h1 => { :font_size => '4em', :color => @style[:header_color] }, 
                                :h2 => { :font_size => '3em', :color => @style[:header_color] }, 
                                :h3 => { :font_size => '2em', :color => @style[:header_color] }, 
                                :h4 => { :font_size => '2em', :color => @style[:header_color] }, 
                                :h5 => { :font_size => '2em', :color => @style[:header_color] }, 
                                :h6 => { :font_size => '2em', :color => @style[:header_color] } 
                     }
              )
    end

    def decorate_images(article, images, pdf)
      media_assets = []
      return unless images.first
      left = true
      images.each { |media_asset| 
        # render image
        ma_id = media_asset.media_asset_id
        pdf.move_down(5)
        pdf.bounding_box([0,0]) do 
          begin 
            pdf.image(Aurita.project.base_path + "public/assets/large/asset_#{ma_id}.jpg", :width => 200)
          rescue ::Exception => ignore
            # Image could be missing
          end
          if media_asset.title then
            pdf.move_down(5)
#           pdf.text(media_asset.title, :size => @style[:font_size], :style => :bold)
          end
          if media_asset.description then
            pdf.move_down(5)
#           pdf.text(media_asset.description, :size => @style[:font_size], :style => :italic)
          end
        end
        pdf.move_down(14)
      }
    end

    def decorate_todo(todo, container_params, pdf)
      return unless todo
      # render todo lists
    end

    def decorate_form(fa, text_asset, article, container_params)
      return unless fa
      Aurita::Main.import_model fa.custom_model_name.downcase
      model_register = Form_Generator::Model_Register.find(1).with(Form_Generator::Model_Register.name == fa.custom_model_name).entity

      model_klass = Aurita::Main.const_get(fa.custom_model_name)
      Aurita::Main.import_controller(fa.custom_model_name.downcase)
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
        form = model_controller.instance_form(entity)
        form.element_template = Lore::GUI::ERB_Template.new(form_element_template)
        form.form_template = Lore::GUI::ERB_Template.new('form_table_blank.rhtml')
        form_asset_entries << { :string => form.string , :entity => entity }
      }

      # TODO: render form
    end

    def recode(txt)
      txt.to_s
    end
    
  end

end
end
end


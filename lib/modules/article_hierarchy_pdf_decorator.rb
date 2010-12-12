
require('aurita')
Aurita.import_plugin_module :wiki, :article_hierarchy_default_decorator

begin
# require('hpricot')
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

  class Article_Hierarchy_PDF_Decorator < Article_Hierarchy_Default_Decorator
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
      article     = @hierarchy[:instance]
      parts       = @hierarchy[:parts]
      @article    = article
      
      Prawn::Document.generate("/tmp/article_#{article.article_id}.pdf", 
                               :page_size    => 'A4', 
                               :left_margin  => 70, 
                               :right_margin => 70) do |pdf|
        pdf.bounding_box([340,770], :height => 50, :width => 50) { 
          pdf.image(Aurita.project.base_path + 'public/images/pdf_banner.png', :height => 50)
        }

        pdf.move_down(20)
        pdf.fill_color(@style[:header_color].sub('#',''))
        pdf.text((article.title), :size => 25)
        pdf.fill_color(@style[:text_color].sub('#',''))

        pdf.move_down(3)
        pdf.text((tl(:pdf_created_at) + ' ' << datetime(DateTime.now)), :size => 8)
        pdf.move_down(10)
        parts.each { |p|
          decorate_part(p[:instance], article, pdf)
        }
      end
      
    end

    def decorate_part(part, article, pdf)
      case part
      when Text_Asset then
        decorate_text(part.text, pdf)
      when Media_Container then
        decorate_images(part.media_assets, pdf)
      end
    end

    def decorate_text(text, pdf)
      text.gsub!(/<p([^>].+)?>/,'<br />')
      text.gsub!('</p>','<br />')
      text.gsub!(/<h(\d)>/,'<br /><h\1>')
      text.gsub!(/<\/\s?h(\d)>/,'</h\1><br />')
      text.gsub!('</ul>',"</ul><br /><br />")
      text.gsub!('</ol>',"</ol><br /><br />")
      coder = HTMLEntities.new
      text  = coder.decode(text)
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

    def decorate_images(images, pdf)
      media_assets = []
      return unless images.first
      images.each { |media_asset| 
        if media_asset.has_preview? then
          ma_id = media_asset.media_asset_id
          pdf.move_down(5)
          begin 
            pdf.image(Aurita.project.base_path + "public/assets/large/asset_#{ma_id}.jpg", :width => 200)
          rescue ::Exception => ignore
            # Image could be missing
          end
          if media_asset.title then
            pdf.move_down(5)
            pdf.text(media_asset.title, :size => @style[:font_size], :style => :bold)
          end
          if media_asset.description then
            pdf.move_down(5)
            pdf.text(media_asset.description, :size => @style[:font_size], :style => :italic)
          end
          pdf.move_down(14)
        end
      }
    end
    
  end

end
end
end


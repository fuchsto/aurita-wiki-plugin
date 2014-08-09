
require('quick_magick')

module Aurita
module Plugins
module Wiki

  class Quick_Magick_Renderer

    @@logger = Aurita::Log::Class_Logger.new(self)

    def initialize(media_asset_instance)
      @media_asset = media_asset_instance
    end
        
    # Convert given media_asset to JPG equivalent
    def import(path)
      @path = path

      id   = @media_asset.media_asset_id
      ext  = @media_asset.extension.dup.downcase
      out_path = Aurita.project_path(:public, :assets, "asset_#{id}.jpg")
      
      @@logger.log "Import #{path}, Image id: #{id}, extension: #{ext}"
      @@logger.log "Output path: #{out_path}"
      begin
      # img = QuickMagick::ImageList.new(path) 
        img = QuickMagick::Image.read(path) { |image| image.density = 150 }

        img = img.first if img.respond_to? :first
        img.write(out_path)
      rescue ::Exception => e
        @@logger.log "IMAGE UP | Error: #{e.message} when trying to import file #{path}"
        raise e
      end

      @media_asset[:width]  = img.columns.to_i
      @media_asset[:height] = img.rows.to_i
      if img.rows.to_i > 0 then # prevent DbZ
        @media_asset[:ratio]  = img.columns.to_f / img.rows.to_f
      end
      @media_asset.commit
    end

    def create_image_variants(variants={})
      @@logger.log "Creating variants"
      
      media_asset_id = @media_asset.media_asset_id
      
      variants.each_pair { |variant_name, procedure|
        @@logger.log "Creating variant #{variant_name}"

        begin
          image_in  = @media_asset.fs_path(:extension => 'jpg')
          image_out = @media_asset.fs_path(:variant   => variant_name)
          
          if (File.exists?(image_in) && !(File.exists?(image_out))) then
            img = QuickMagick::Image.new(image_in)
            procedure.call(img, @media_asset)
            File.chmod(0777, image_out)
          else 
            @@logger.log "Skipping image variant #{variant_name}"
            @@logger.log "as variant exists: #{image_out}"
            @@logger.log "or input file is missing: #{image_in}"
          end
        rescue ::Exception => excep
          @@logger.log "Failed to generate image variant for #{image_in}"
          @@logger.log "Exception was: #{excep.message}"
          excep.backtrace.each { |l| STDERR.puts(l) }
        end
      }
    end

    def create_pdf_preview()
      id   = @media_asset.media_asset_id
      ext  = @media_asset.extension.dup.downcase
      path = Aurita.project_path(:public, :assets, "asset_#{id}.#{ext}")
      
      @@logger.log "--- Rendering #{path} ---"
      
      img = QuickMagick::Image.read(path) { |image| image.density = 150 }
       
      img.first.save(Aurita.project_path(:public, :assets, "asset_#{id}.jpg")) 

      if Aurita.project.full_pdf_rendering then 
        # Additionally export all pages of PDF as separate (large) images
        # in paths like 
        #   asset_<media_asset_id>-<page idx>.jpg
        
        img.each_with_index { |page, i|
          @@logger.log "--- -> asset_#{id}-#{i}.png"
          page.save(Aurita.project_path(:public, :assets, "asset_#{id}-#{i}.png")) 
        }
      end
    end

  end

end
end
end


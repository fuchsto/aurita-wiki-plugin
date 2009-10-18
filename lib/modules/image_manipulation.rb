
require('aurita')
require('RMagick')
Aurita.import_plugin_module :wiki, :media_asset_helpers

module Aurita
module Plugins
module Wiki

  # Usage: 
  #  
  #   im = Image_Manipulation.new(media_asset)
  #   im.rotate_left
  #   im.mirror_horizontal
  #   im.manipulate(:contrast => 70)
  #   im.create_preview
  #
  #   ... Display preview image, accept further operations ...
  #
  #  When saving changes on image: 
  #
  #   im = Image_Manipulation.new(media_asset)
  #   im.create_image_tempfiles
  #   im.save
  #   im.close
  #
  # Image_Manipulation#close has to be called when 
  # no further operations are expected and all 
  # temporary files may be deleted. 
  #
  class Image_Manipulation
  include Media_Asset_Helpers
  include Magick

    @@logger = Aurita::Log::Class_Logger.new(self)

    def initialize(media_asset_instance)
      @media_asset    = media_asset_instance
      @media_asset_id = @media_asset.media_asset_id
      @img_work_path  = Aurita.project_path + "public/assets/tmp/asset_#{@media_asset_id}_work.#{@media_asset.mime_extension}"
      @img_org_path   = Aurita.project_path + "public/assets/tmp/asset_#{@media_asset_id}_org.#{@media_asset.mime_extension}"
      @@logger.log('MANIP: @img work is ' << @img_work_path) 
      @@logger.log('MANIP: @img src is ' << @media_asset.original_image_path) 
      @img = nil
      @img_opened = false
      @work_count = 0
      @preview_width = 300
      @preview_height = 300
    end

  private
    def open_image
      return if @img_opened
      FileUtils.copy(@media_asset.original_image_path, @img_work_path)
    # FileUtils.copy(@media_asset.original_image_path, @img_org_path)
      @img = ImageList.new(@img_work_path)
      @img_opened = true
    end

  public
    def for_image(magick_image)
      @img = magick_image
      self
    end
    
    # Creates version _show of instantiated Media_Asset instance
    def create_preview
    # {{{ 
      open_image()
      @img.resize_to_fit!(300, 30000) # Force adjustment to width only
      @img.write(temp_filename_for(@media_asset_id + '_show'))
    end # }}}

    private
  
    def write_work_version
      open_image()
      @img.write(@img_work_path)
    end

    public

    # Return attribute hash for temporary image of Media_Asset instance 
    # this instance has been instantiated with: 
    # 
    #  Image_Manipulation.new(media_asset_instance).image_info('work')
    #  --> Info for /tmp/aurita/asset_123_work.jpg
    #     { 
    #       :extension => '.gif', 
    #       :width     => 200, 
    #       :height    => 100, 
    #       :ratio     => 0.5  (height / width)
    #     }
    def image_info(version=nil)
    # {{{
      open_image()
      info = {}
      version = '_' << version if version
      id = @media_asset_id
      info[:extension] = '.' << @media_asset.mime_extension
      info[:width]  = @img.columns().to_i 
      info[:height] = @img.rows().to_i 
      info[:ratio]  = (info[:height].to_f / info[:width].to_f) 
      return info
    end # }}}

    def rotate(degree=0)
      id = @media_asset_id
      open_image()
      @img.rotate!(degree.to_i)
#     write_work_version()
    end
    
    def mirror(direction)
      id = @media_asset.media_asset_id
      open_image()
      @img.flip! if direction == :v 
      @img.flop! if direction == :h 
#     write_work_version()
    end

    # Crop instantiated magick image according to parameters: 
    #   :crop_top    => Integer, height in pixels to crop from top
    #   :crop_bottom => Integer, height in pixels to crop from bottom
    #   :crop_left   => Integer, height in pixels to crop from left
    #   :crop_right  => Integer, height in pixels to crop from right
    #   :height      => Integer, height of preview image to generate
    #   :width       => Integer, width of preview image to generate. 
    # Important: You will mess up the aspect ratio when not providing 
    # correct height and width. 
    def crop(crop_params={})
    # {{{
      open_image()
      STDERR.puts 'IMG_CROP_IMAGE: ' << crop_params.inspect
      crop_top    = crop_params[:crop_top].to_i unless crop_top
      crop_bottom = (crop_params[:crop_bottom].to_i) * -1 unless crop_bottom
      crop_left   = crop_params[:crop_left].to_i unless crop_left
      crop_right  = (crop_params[:crop_right].to_i) * -1 unless crop_right
      height      = crop_params[:height].to_i
      width       = 300
      
      percentage_top    = 100 * crop_top / height
      percentage_bottom = 100 * crop_bottom / height
      percentage_left   = 100 * crop_left / width
      percentage_right  = 100 * crop_right / width  
      
      img_width = img.columns()
      img_height = img.rows()
      
      crop_x = img_width * percentage_left / 100
      crop_y = img_height * percentage_top / 100
      crop_width = (img_width - crop_x) - (img_width * percentage_right / 100)
      crop_height = (img_height - crop_y) - (img_height * percentage_bottom / 100)

      @img = @img.crop(crop_x, crop_y, crop_width, crop_height)
#     write_work_version()
    end # }}}
    
    # Reset manipulated image to original state
    def reset()
    # {{{
      open_image()
      id = @media_asset_id
      FileUtils.copy(Aurita.project_path + 'public/assets/tmp/asset_' << id + '_org.jpg', 
                     Aurita.project_path + 'public/assets/asset_' << id + '.jpg')
      write_work_version()
      create_preview(); 
    end # }}}

    # Commits modified version back to original image file. 
    # Also deletes temp files and creates previews for all image sizes. 
    def save()
      open_image()
      # Copy to original file system path so file extension 
      # is conserved: 
      @img.write(@media_asset.fs_path)
      create_image_versions()
      delete_image_tempfiles()
    end

    # Load previous working version of image and use it as current working image. 
    # Also creates new preview from previous image version. 
    def undo
      open_image()
      @img = ImageList.new(temp_filename_for(@media_asset_id + '_work_' << (@work_count-1).to_s))
      write_work_version()
      create_preview()
    end

    def close()
      delete_image_tempfiles()
      @img.delete!
      @img = nil
      GC.start
    end

    # Create temporary files required for manipulation progress: 
    #
    #   asset_<id>_org.jpg
    #     - Copy of original image
    #   asset_<id>_work.jpg
    #     - Current working copy
    #   asset_<id>_show.jpg
    #     - Preview image e.g. to display in editor
    def create_image_tempfiles()
    # {{{
      open_image()
      id = @media_asset.media_asset_id
      @img.write(Aurita.project_path + 'public/assets/tmp/asset_' << id + '_org.jpg')
      @img.write(Aurita.project_path + 'public/assets/tmp/asset_' << id + '_work.jpg')
      @img.resize_to_fit!(@preview_width, @preview_height)
      @img.write(Aurita.project_path + 'public/assets/tmp/asset_' << id + '_show.jpg')
    end # }}}

    # Delete all temporary files that have been created in this 
    # working process. 
    def delete_image_tempfiles 
    # {{{
      open_image()
      id = @media_asset.media_asset_id
      File.delete_if_exists(temp_filename_for(id + '_show.jpg'))
      File.delete_if_exists(temp_filename_for(id + '_org.jpg'))
      count = 0
      while File.exists?(temp_filename_for(id + '_work_' << count.to_s)) do
        FileUtils.remove(temp_filename_for(id + '_work_' << count.to_s))
        count += 1
      end
      File.delete_if_exists(temp_filename_for(id + '_work'))
      File.delete_if_exists(temp_filename_for(id + '_mod'))
      # Flush working image and version count, so we operate on 
      # an unchanged version on next Image_Manipulation.new
      @img = ImageList.new(@media_asset.fs_path) 
      @work_count = 0
    end # }}}

    # Generate all thumbnail sizes from given magick image
    def create_image_variants(variants)
    # {{{
      @@logger.log('Creating image versions. ')
      media_asset_id = @media_asset.media_asset_id
      
      variants.each_pair { |variant_name, procedure|
        begin
          image_in  = @media_asset.fs_path(:extension => 'jpg')
          image_out = @media_asset.fs_path(:variant   => variant_name)
          
          if (File.exists?(image_in) && !(File.exists?(image_out))) then
            @@logger.log("Creating image variant #{variant_name}: #{image_in}")
            img = ImageList.new(image_in)
            procedure.call(img, @media_asset)
            File.chmod(0777, image_out)
          else 
            @@logger.log("Skipping image variant #{variant_name}")
            @@logger.log("as variant exists: #{image_out}")
            @@logger.log("or input file is missing: #{image_in}")
          end
        rescue ::Exception => excep
          @@logger.log("Failed to generate image variant: #{image_in}")
          @@logger.log("Exception was: #{excep.message}")
          excep.backtrace.each { |l| @@logger.log(l) }
        end
      }
    end # }}}

    # Change image parameters: 
    #    :brightness => Float, default 1.0
    #    :saturation => Float, default 1.0
    #    :hue        => Float, default 1.0
    #    :contrast   => Integer, default 100
    def change_params(params)
    # {{{
    
#     FileUtils.copy(temp_filename_for(@media_asset_id+'_work'), 
#                    temp_filename_for(@media_asset_id+'_work_' << @work_count.to_s + '_mod'))
#     mod_image = ImageList.new(temp_filename_for(@media_asset_id+'_work_' << @work_count.to_s + '_mod'))
    
      open_image()

      params[:brightness] = 1.0 if params[:brightness].nil?
      params[:saturation] = 1.0 if params[:saturation].nil?
      params[:hue]        = 1.0 if params[:hue].nil?
      params[:contrast]   = 100 if params[:contrast].nil?
      if params[:contrast].to_i > 100 then
        white_point = 100
        black_point = params[:contrast].to_i - 100
      else
        white_point = params[:contrast].to_i
        black_point = 0
      end
      
      begin
        @img = @img.contrast_stretch_channel(black_point.to_s + '%', white_point.to_s + '%')
      rescue ::Exception => excep
        # Not supported by older versions of ImageMagick
      end
      @img = @img.modulate(params[:brightness].to_f, params[:saturation].to_f, params[:hue].to_f)
#     write_work_version()
    end # }}}

  end

end
end
end


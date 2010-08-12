
require('aurita')
require('mini_magick') if Aurita::App_Configuration.use_mini_magick

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
  class Mini_Magick_Image_Manipulation_Strategy < Image_Manipulation_Strategy
  include Media_Asset_Helpers
  include MiniMagick if Aurita::App_Configuration.use_mini_magick

    @@logger = Aurita::Log::Class_Logger.new(self)


    # Adapter class for RMagick ImageList to MiniMagick Image
    #
    class Magick_ImageList_Adapter
      def initialize(path)
        @img      = MiniMagick::Image.from_file(path)
        @img_path = path
      end

      def resize_to_fit(x,y)
        @img.resize("#{x}X#{y}")
        return self
      end

      def resize_to_fit!(x,y)
        resize_to_fit(x,y)
        write(@img_path)
      end

      def write(path, &block)
        @img.write(path)
        return self
      end

      def rotate(degrees)
        @img.rotate(degrees)
        return self
      end

      def rotate!(degrees)
        rotate(degrees)
        write(@img_path)
      end

      def crop(x,y, w,h)
        @img.crop(x,y, w,h)
        return self
      end

      def crop!(x,y, w,h)
        crop(x,y, w,h)
        write(@img_path)
      end

      def flip!
      end

      def flop!
      end
    end

    def initialize(media_asset_instance)
      @manip_strategy_klass = Magick_ImageList_Adapter
      super()
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


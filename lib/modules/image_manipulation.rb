
require('aurita')

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

    def initialize(media_asset)
      if Aurita::App_Configuration.use_magick then
        Aurita.import_plugin_module :wiki, :magick_image_manipulation_strategy
        return Magick_Image_Manipulation_Strategy.new(media_asset)
      elsif Aurita::App_Configuration.use_mini_magick then
        Aurita.import_plugin_module :wiki, :mini_magick_image_manipulation_strategy
        return MiniMagick_Image_Manipulation_Strategy.new(media_asset)
      end
    end

  end

end
end
end



require('aurita/plugin_controller')
Aurita.import_plugin_module :wiki, :image_manipulation

module Aurita
module Plugins
module Wiki

  class Image_Editor_Controller < Aurita::Plugin_Controller

    def main
    # {{{
      renderer = Media_Asset_Renderer.new(param(:media_asset_id))
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      raise Aurita::Runtime_Error.new(tl(:file_is_no_image)) unless media_asset.is_image?

      manip = Image_Manipulation.new(media_asset)
      # Delete previous tempfiles, if any
      manip.delete_image_tempfiles(); 
      # Create new tempfiles for image
      manip.create_image_tempfiles(); 
      manip.create_preview(); 
      info = manip.image_info
      info[:width]  = 300
      info[:height] = info[:width] * info[:ratio]
      render_view(:image_editor, 
                  :media_asset_id => param(:media_asset_id), 
                  :info => info)
      exec_js("Aurita.ImageEditor.init_image_manipulation(); 
               Aurita.ImageEditor.active_media_asset_id=#{param(:media_asset_id)}; ")
    end # }}}

    def manipulate()
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      renderer.mirror(:h) if param(:mirror_h) == 'true'; 
      renderer.mirror(:v) if param(:mirror_v) == 'true'; 
      renderer.rotate(param(:rotation).to_i) if param(:rotation).to_s != '0'
      renderer.change_params(@params)
      renderer.create_preview()
    end 

    def save
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      renderer.mirror(:h) if param(:mirror_h) == 'true'; 
      renderer.mirror(:v) if param(:mirror_v) == 'true'; 
      renderer.rotate(param(:rotation).to_i) if param(:rotation).to_s != '0'
      renderer.change_params(@params)
      renderer.create_preview()
      renderer.save()
    end

    def reset
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      renderer.reset()
    end

    def undo
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      renderer.change_params(@params)
      renderer.undo()
      renderer.create_preview()
    end

  private
    def rotate(degree)
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      renderer.rotate(degree)
      renderer.create_preview()
    end
    def mirror(direction)
      media_asset = Media_Asset.load(:media_asset_id => param(:media_asset_id))
      renderer = Image_Manipulation.new(media_asset)
      renderer.mirror(direction)
      renderer.create_preview()
    end

  public
    def rotate_left
      rotate(-90)
    end
    def rotate_right
      rotate(90)
    end
    def mirror_horizontal
      mirror(:h)
    end
    def mirror_vertical
      mirror(:v)
    end

  end

end
end
end

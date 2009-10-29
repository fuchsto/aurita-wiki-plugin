
module Aurita
module Plugins
module Wiki

  class Media_Meta_Data

    attr_reader :exif, :iptc

    def initialize(media_asset, params={})
      @exif  = {}
      @iptc  = ''
      @error = false
      begin
        img = Magick::Image.read(media_asset.fs_path(params)).first
        img.format = 'iptctext'
        @iptc = img.to_blob
        img.get_exif_by_entry.each { |a,b|
          @exif[a] = b
        }
      rescue ::Exception => e
        @error = true
      end
    end

  end

end
end
end


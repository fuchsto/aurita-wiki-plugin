
require('mini_magick')

module Aurita
module Plugins
module Wiki

  class MiniMagickRenderer

    @@logger = Aurita::Log::Class_Logger.new(self)

    def initialize(media_asset_instance)
      @media_asset = media_asset_instance
    end

    def import
    end

    def create_variants(variants={})
    end

    def create_pdf_preview()
    end

  end

end
end
end

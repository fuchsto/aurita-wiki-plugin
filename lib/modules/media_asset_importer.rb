
require('aurita')
require('fileutils')
require('RMagick')
require('rubygems')
require('mime/types')
Aurita.import_plugin_module :wiki, :media_asset_helpers
Aurita.import_plugin_module :wiki, :image_manipulation

module Aurita
module Plugins
module Wiki

  class Media_Asset_Importer
  include Media_Asset_Helpers
  include Magick

    @@variants = {}

    @@logger = Aurita::Log::Class_Logger.new(self)

    # Add an image variant. Example: 
    #
    #   Media_Asset_Importer.add_variant(:huge) { |image, media_asset|
    #     image.resize_to_fit(2000,2000).quality(100).write(Aurita.project_path + "public/assets/huge/asset_#{media_asset.media_asset_id}.jpg")
    #   }
    #
    #
    def self.add_variant(name, &block)
      @@variants[name.to_sym] = block 
    end
    # Same as self.add_variant
    def self.set_variant(name, &block)
      @@variants[name.to_sym] = block 
    end

    # Remove an image variant. 
    #
    #   Media_Asset_Importer.remove_variant(:huge)
    #
    def self.remove_variant(name)
      @@variants.delete_at(name.to_sym)
    end

    @@logger = Aurita::Log::Class_Logger.new(self)
    add_variant(:medium) { |img, asset|
      img.resize_to_fit(320,320).write(Aurita.project_path + "public/assets/medium/asset_#{asset.media_asset_id}.jpg") { self.quality = 82 }
    }
    add_variant(:thumb) { |img, asset|
      img.resize_to_fit(120,120).write(Aurita.project_path + "public/assets/thumb/asset_#{asset.media_asset_id}.jpg") { self.quality = 82 }
    }
    add_variant(:small) { |img, asset|
      img.resize_to_fit(95,95).write(Aurita.project_path + "public/assets/small/asset_#{asset.media_asset_id}.jpg") { self.quality = 82 }
    }
    add_variant(:tiny) { |img, asset| 
      img.resize_to_fit(70,70).write(Aurita.project_path + "public/assets/tiny/asset_#{asset.media_asset_id}.jpg") { self.quality = 82 }
    } 

    def self.variants
      @@variants
    end
    def self.image_variants
      @@variants
    end

    # Expects instance of Wiki::Media_Asset (or sub type) to 
    # import file for. 
    # Note that attributes filesize, mime, and mime_extension are 
    # overwritten in #import
    def initialize(media_asset_instance)
      @media_asset = media_asset_instance
    end

    # Expects Hash containing file information, like 
    #
    #   { :filesize          => <filesize in bytes>, 
    #     :type              => 'application/x-pdf', 
    #     :server_filename   => 'path/to/file.pdf', 
    #     :original_filename => 'document.pdf' }
    #
    # Parameter :server_filename is relative path from project's asset
    # upload folder, such as 'projects/the_project/public/assets/tmp/'. 
    #
    # Parameter :original_filename is optional for compatibility with 
    # Ruby CGI upload procedure. 
    #
    def import(file_info={})
    # {{{ 
      id = @media_asset.media_asset_id
      @@logger.log("FILE IMPORT File info: #{file_info.inspect}")
      @media_asset.extension   = file_info[:original_filename].split('.')[-1].downcase if file_info[:original_filename]
      @media_asset.extension ||= file_info[:server_filename].split('.')[-1].downcase
      @media_asset.mime        = file_info[:type]
      @media_asset.filesize    = file_info[:filesize]
      @media_asset.checksum    = file_info[:md5_checksum]
      @media_asset.commit
      @@logger.log("FILE IMPORT FS path: #{@media_asset.fs_path}")
      @@logger.log("FILE IMPORT MIME: #{@media_asset.mime}")
      @@logger.log("FILE IMPORT MIME extension: #{@media_asset.extension}")
      extension = @media_asset.extension

      begin
        FileUtils.move(file_info[:server_filepath], @media_asset.fs_path)
      rescue ::Exception => e
        raise ::Exception.new("Failed to import file from path #{file_info[:server_filepath].inspect} to #{@media_asset.fs_path.inspect}. Media asset: #{@media_asset.inspect}")
      end
      File.chmod(0777, @media_asset.fs_path)

      @@logger.log('IMAGE UP | Importing')
      if @media_asset.has_preview? then
        @@logger.log('FILE IMPORT: Create preview')
        create_thumbnails()
      elsif @media_asset.is_movie? and @media_asset.mime != 'application/x-flv' then
        system('ffmpeg -i ' << @media_asset.fs_path + ' ' << Aurita.project_path + 'public/assets/asset_' << id + '.flv')
        FileUtils.remove(@media_asset.fs_path)
        @media_asset['mime'] = 'application/x-flv'
        @media_asset.commit 
      else 
        @@logger.log('No preview created')
      end
      @@logger.log('IMAGE: Exiting')
    end # }}}

    # Move current version (filename has no version suffix) to last version 
    # (filename has suffix with highest version), e.g.
    #
    #   asset_1234.jpg => asset_1234.x.jpg   (x+1 being most recent version number)
    #   
    def import_new_version(file_info={})

      FileUtils.move(@media_asset.fs_path(), 
                     @media_asset.fs_path(:version => @media_asset.version.to_s))
      if @media_asset.has_preview? then
        @@variants.keys.each { |v| 
          begin
            FileUtils.move(@media_asset.fs_path(:size => v), 
                           @media_asset.fs_path(:size => v, :version => @media_asset.version.to_s))
          rescue ::Exception => excep
            @@logger.log("Could not save version for image variant: #{@media_asset.fs_path(:size => v, :version => @media_asset.version.to_s)}")
          end
        }
      end
      import(file_info)
    end

    # Copy old version to current one, e.g. 
    #
    #   asset_1234.x.jpg => asset_1234.jpg   (x being version number to rollback to)
    #   
    def rollback_version(version)
      FileUtils.copy(@media_asset.fs_path(:version => version.to_s), 
                     @media_asset.fs_path())
      if @media_asset.has_preview? then
        @@variants.keys.each { |v| 
          FileUtils.move(@media_asset.fs_path(:size => v), 
                         @media_asset.fs_path(:size => v, :version => @media_asset.version.to_s))
          FileUtils.copy(@media_asset.fs_path(:size => v, :version => version.to_s), 
                         @media_asset.fs_path(:size => v))
        }
      end
    end

    # Uses Wiki::Image_Manipulation to create thumbnail image variants 
    # defined via Media_Asset_Importer.add_variant. 
    def create_thumbnails()
    # {{{
      begin
        @@logger.log('IMAGE UP | Importing image')
        id  = @media_asset.media_asset_id

        ext = @media_asset.extension.dup.downcase
        ext << '[0]' if ext == 'pdf' # Only render first page of PDF

        path = Aurita.project_path(:public, :assets, "asset_#{id}.#{ext}")
        @@logger.log("IMAGE UP | Path is #{path}")
        # Every image needs a jpeg base image (esp. needed for PDF): 
        begin
          img = ImageList.new(path) 
        rescue ::Exception => e
          @@logger.log("IMAGE UP | Error: #{e.message}")
          raise ::Exception.new('Error importing file: ' << path)
        end
        img.write(Aurita.project_path(:public, :assets, "asset_#{id}.jpg"))
        
        Image_Manipulation.new(@media_asset).create_image_variants(@@variants)
      rescue ::Exception => e
        @@logger.log('Error when trying to create image versions: ' << e.message)
        e.backtrace.each { |m| 
          @@logger.log(m)
        }
      end
    end # }}}

    def import_local_file(file_or_filename)
    # {{{
    
      file      = false
      file_path = false
      if file_or_filename.is_a? String then
        size    ||= File.size(file_or_filename) 
        file_path = file_or_filename
      elsif file_or_filename.respond_to?(:read)
        size = file_or_filename.length 
        file = file_or_filename
        file_path = File.path
      end

      size ||= 0
      file_info = {
        :filesize => size, 
        :type => @media_asset.mime, 
        :server_filename   => @media_asset.original_filename, 
        :server_filepath   => file_path, 
        :original_filename => @media_asset.original_filename
      }

      server_filename = file_info[:server_filename]
      @@logger.log 'Import file from ' << file_path.inspect
      @@logger.log 'Import file to ' << Aurita.project_path + 'public/assets/tmp/' << server_filename
      if file_or_filename.is_a? String then
        dest_path = Aurita.project_path + 'public/assets/tmp/' << server_filename
        FileUtils.copy(file_path, dest_path) if file_path != dest_path
      elsif file_or_filename.respond_to?(:read)
        File.open(Aurita.project_path + 'public/assets/tmp/' << server_filename, "w") { |f|
          f.write(file.read)
        }
      end
      import(file_info)
    end # }}}
    
    def import_folder(folder_path, media_folder_id__parent, tags='')
    # {{{

      raise ::Exception.new('Folder does not exist') unless File.exists? folder_path

      @@logger.log 'import_folder(' << folder_path.inspect + ',' << media_folder_id__parent.inspect + ',' << tags.inspect + ')'

      rio(folder_path).all.files { |file|
        if file.dir? then
          folder_name = file.fspath.split('/')[-1]
          folder = Media_Asset_Folder.create(:physical_path => folder_name, 
                                             :media_folder_id__parent => media_folder_id__parent)
          import_folder(file.fspath, folder.media_asset_folder_id)
        else
          ext = file.fspath.split('.')[-1].downcase
          if ['jpeg','jpg'].include? ext then
#         if file.fspath[0] != '.' then
            @@logger.log 'FILE: ' << file.fspath
            asset = Media_Asset.create(:mime => 'image/jpeg', 
                                       :tags => tags, 
                                       :media_folder_id => media_folder_id__parent)
            begin
              import_local_file(asset, file.fspath)
            rescue ::Exception => excep
              if asset then asset.delete end
              @@logger.log 'Exception: ' << excep.message
            end
          end
        end
      }
    end # }}}

    def import_zip(zip_path, media_folder_id, tags)
    # {{{
      @@logger.log 'import_zip(' << zip_path.inspect + ',' << media_folder_id.inspect + ',' << tags.inspect + ')'
      zip = rio(zip_path.dup)
      ext = zip.fspath.split('.')[-1].downcase

      tmp_dir = '/tmp/aurita/' << Aurita.user.user_group_id
      FileUtils.mkdir(tmp_dir)
      tmp_path = tmp_dir + Aurita.user.user_group_id + '.zip'
      tmp_path = zip_path
      zip >> tmp_path.dup
      zip = rio(tmp_path.dup)

      if ext == 'zip' then
        @@logger.log 'SYSCALL: ' << "unzip "+tmp_path+" -d "+tmp_dir
        system("unzip "+tmp_path+" -d "+tmp_dir)
        import_folder(tmp_dir, media_folder_id, tags)
      elsif ext == 'rar' then
        
      elsif ext == 'gz' or ext == 'tgz' then
        
      end
      @@logger.log 'SYSCALL: rm -Rf '+tmp_dir
      system("rm -Rf "+tmp_dir)
    end # }}} 

  end

end
end
end
